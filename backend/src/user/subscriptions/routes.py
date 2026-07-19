import re
from datetime import datetime, timedelta
from pathlib import Path
from random import SystemRandom
from urllib.parse import urlencode
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import (PaymentSetting, PaymentStatus, SubscriptionPayment,
    SubscriptionPlan, SubscriptionStatus, User, UserDigiDocument, UserMediaItem,
    UserSubscription, UserVaultFile)
from src.database.session import get_db
from src.core.notifications import send_event_push
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.subscriptions.quota import storage_status

router = APIRouter(prefix="/subscription", tags=["subscriptions"])
SCREENSHOT_DIR = Path("src/private_uploads/payment_screenshots")
MAX_SCREENSHOT_BYTES = 5 * 1024 * 1024
UTR_PATTERN = re.compile(r"^[A-Za-z0-9-]{8,64}$")

class CreatePaymentRequest(BaseModel):
    plan_id: int

def plan_data(plan: SubscriptionPlan) -> dict:
    return {"id": plan.id, "code": plan.code, "name": plan.name, "description": plan.description,
        "storage_gb": plan.storage_gb, "price_paise": plan.price_paise,
        "price_inr": plan.price_paise / 100, "billing_days": plan.billing_days,
        "features": plan.features, "why_purchase": plan.why_purchase,
        "is_premium": plan.is_premium, "is_active": plan.is_active, "sort_order": plan.sort_order}

async def seed_plans(db: AsyncSession) -> None:
    if await db.scalar(select(func.count()).select_from(SubscriptionPlan)): return
    defaults = [
        ("monthly-1", "Monthly Starter", 1, 4900, 30, False, ["1 GB secure cloud space", "All vault essentials"], ["Flexible monthly access"]),
        ("quarterly-3", "Quarterly Plus", 3, 9900, 90, False, ["3 GB secure cloud space", "Priority sync"], ["More space at a lower per-GB price"]),
        ("yearly-5", "Yearly Pro", 5, 14900, 365, False, ["5 GB secure cloud space", "Priority support"], ["Best for regular backups"]),
        ("premium-10", "Premium Yearly", 10, 24900, 365, True, ["10 GB secure space", "All plan features", "Priority support", "Early premium tools"], ["Best value per GB", "One plan for every VaultOne module"]),
    ]
    for order, (code, name, gb, price, days, premium, features, why) in enumerate(defaults):
        db.add(SubscriptionPlan(code=code, name=name, storage_gb=gb, price_paise=price, billing_days=days, is_premium=premium, features=features, why_purchase=why, sort_order=order))
    await db.commit()

async def get_settings(db: AsyncSession) -> PaymentSetting:
    setting = await db.scalar(select(PaymentSetting).order_by(PaymentSetting.id).limit(1))
    if not setting:
        setting = PaymentSetting(); db.add(setting); await db.commit(); await db.refresh(setting)
    return setting

async def expire_requests(db: AsyncSession, user_id: int | None = None) -> None:
    query = select(SubscriptionPayment).where(SubscriptionPayment.status == PaymentStatus.created, SubscriptionPayment.expires_at <= datetime.utcnow())
    if user_id is not None: query = query.where(SubscriptionPayment.user_id == user_id)
    rows = (await db.scalars(query)).all()
    for row in rows: row.status = PaymentStatus.expired
    if rows: await db.commit()

def payment_data(payment: SubscriptionPayment, plan: SubscriptionPlan | None = None) -> dict:
    return {"id": payment.id, "order_id": payment.order_id, "plan_id": payment.plan_id,
        "plan_name": plan.name if plan else None, "status": payment.status.value,
        "amount_paise": payment.payable_amount_paise, "amount_inr": payment.payable_amount_paise / 100,
        "paid_amount_paise": payment.paid_amount_paise, "utr": payment.utr,
        "rejection_reason": payment.rejection_reason, "expires_at": payment.expires_at,
        "submitted_at": payment.submitted_at, "created_at": payment.created_at}

@router.get("/plans", response_model=DataResponse)
async def plans(db: AsyncSession = Depends(get_db), _: User = Depends(get_current_user)) -> DataResponse:
    await seed_plans(db)
    rows = (await db.scalars(select(SubscriptionPlan).where(SubscriptionPlan.is_active.is_(True)).order_by(SubscriptionPlan.sort_order))).all()
    return DataResponse(message="Plans fetched", data=[plan_data(x) for x in rows])

@router.post("/create-payment", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def create_payment(payload: CreatePaymentRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await expire_requests(db, user.id)
    setting, plan = await get_settings(db), await db.get(SubscriptionPlan, payload.plan_id)
    if not setting.payments_enabled or not setting.upi_id.strip(): raise HTTPException(status_code=503, detail="UPI payments are currently unavailable")
    if not plan or not plan.is_active: raise HTTPException(status_code=404, detail="Plan not found")
    existing = await db.scalar(select(SubscriptionPayment).where(SubscriptionPayment.user_id == user.id, SubscriptionPayment.plan_id == plan.id, SubscriptionPayment.status == PaymentStatus.created, SubscriptionPayment.expires_at > datetime.utcnow()))
    if existing: payment = existing
    else:
        payment = None
        suffixes = list(range(1, 100)); SystemRandom().shuffle(suffixes)
        for suffix in suffixes:
            amount = plan.price_paise + suffix
            collision = await db.scalar(select(SubscriptionPayment.id).where(SubscriptionPayment.payable_amount_paise == amount, SubscriptionPayment.status.in_([PaymentStatus.created, PaymentStatus.pending_verification])))
            if not collision:
                payment = SubscriptionPayment(order_id=f"VO-{datetime.utcnow():%Y%m%d}-{uuid4().hex[:12].upper()}", user_id=user.id, plan_id=plan.id, base_amount_paise=plan.price_paise, payable_amount_paise=amount, expires_at=datetime.utcnow() + timedelta(minutes=setting.request_expiry_minutes))
                db.add(payment); await db.commit(); await db.refresh(payment); break
        if payment is None: raise HTTPException(status_code=503, detail="Could not reserve a unique amount. Try again shortly.")
    amount_text = f"{payment.payable_amount_paise / 100:.2f}"
    uri = "upi://pay?" + urlencode({"pa": setting.upi_id, "pn": setting.receiver_name, "am": amount_text, "cu": "INR", "tn": f"VaultOne {payment.order_id}", "tr": payment.order_id})
    data = payment_data(payment, plan) | {"upi_id": setting.upi_id, "receiver_name": setting.receiver_name, "upi_uri": uri, "instructions": setting.instructions, "qr_available": bool(setting.qr_code_path)}
    return DataResponse(message="Payment request created", data=data)

@router.post("/submit-payment", response_model=DataResponse)
async def submit_payment(order_id: str = Form(...), utr: str = Form(...), paid_amount_paise: int = Form(..., gt=0), screenshot: UploadFile = File(...), db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    payment = await db.scalar(select(SubscriptionPayment).where(SubscriptionPayment.order_id == order_id, SubscriptionPayment.user_id == user.id))
    if not payment: raise HTTPException(status_code=404, detail="Payment request not found")
    if payment.status != PaymentStatus.created: raise HTTPException(status_code=409, detail=f"Payment is already {payment.status.value}")
    if payment.expires_at <= datetime.utcnow(): payment.status = PaymentStatus.expired; await db.commit(); raise HTTPException(status_code=410, detail="Payment request expired")
    normalized_utr = utr.strip().upper()
    if not UTR_PATTERN.fullmatch(normalized_utr): raise HTTPException(status_code=422, detail="Enter a valid 8-64 character UTR")
    if await db.scalar(select(SubscriptionPayment.id).where(SubscriptionPayment.utr == normalized_utr)): raise HTTPException(status_code=409, detail="This UTR has already been submitted")
    if paid_amount_paise != payment.payable_amount_paise: raise HTTPException(status_code=422, detail="Paid amount must exactly match the requested amount")
    extension = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(screenshot.content_type or "")
    if not extension and screenshot.filename:
        suffix = Path(screenshot.filename).suffix.lower()
        if suffix in {".jpg", ".jpeg", ".png", ".webp"}:
            extension = ".jpg" if suffix == ".jpeg" else suffix
    if not extension: raise HTTPException(status_code=415, detail="Screenshot must be JPEG, PNG, or WEBP")
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True); destination = SCREENSHOT_DIR / f"{uuid4().hex}{extension}"; written = 0
    try:
        with destination.open("wb") as output:
            while chunk := await screenshot.read(1024 * 1024):
                written += len(chunk)
                if written > MAX_SCREENSHOT_BYTES: raise HTTPException(status_code=413, detail="Screenshot must be smaller than 5 MB")
                output.write(chunk)
    except Exception: destination.unlink(missing_ok=True); raise
    payment.utr, payment.paid_amount_paise, payment.screenshot_path = normalized_utr, paid_amount_paise, str(destination)
    payment.status, payment.submitted_at = PaymentStatus.pending_verification, datetime.utcnow()
    await db.commit()
    await send_event_push(
        db, title="Payment submitted", body="We received your payment proof and will verify it shortly.",
        user_id=user.id, event_type="payment_submitted",
        data={"route": "/subscriptions", "order_id": payment.order_id},
    )
    return DataResponse(message="Payment submitted for admin verification", data=payment_data(payment))

@router.get("/status", response_model=DataResponse)
async def payment_status(order_id: str | None = None, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await expire_requests(db, user.id)
    expired_subscriptions = (await db.scalars(select(UserSubscription).where(UserSubscription.user_id == user.id, UserSubscription.status == SubscriptionStatus.active, UserSubscription.expires_at <= datetime.utcnow()))).all()
    for expired in expired_subscriptions: expired.status = SubscriptionStatus.expired
    if expired_subscriptions: await db.commit()
    query = select(SubscriptionPayment).where(
        SubscriptionPayment.user_id == user.id,
        SubscriptionPayment.status != PaymentStatus.created,
    )
    if order_id: query = query.where(SubscriptionPayment.order_id == order_id)
    payments = (await db.scalars(query.order_by(SubscriptionPayment.created_at.desc()).limit(20))).all()
    quota = await storage_status(db, user.id)
    subscription = quota.pop("subscription")
    offers = quota.pop("offers")
    return DataResponse(message="Payment and storage status fetched", data={
        "payments": [payment_data(x) for x in payments],
        "subscription": None if not subscription else {"id": subscription.id, "plan_id": subscription.plan_id, "storage_gb": subscription.storage_gb, "status": subscription.status.value, "starts_at": subscription.starts_at, "expires_at": subscription.expires_at},
        "storage": quota,
        "offers": [{"id": x.id, "plan_id": x.plan_id, "title": x.title, "description": x.description, "discount_percent": x.discount_percent, "offer_price_paise": x.offer_price_paise, "expires_at": x.expires_at} for x in offers],
    })
