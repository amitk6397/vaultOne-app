from datetime import datetime, timedelta
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.database.models import (Admin, PaymentAuditLog, PaymentSetting, PaymentStatus,
    SubscriptionPayment, SubscriptionPlan, SubscriptionStatus, User,
    UserSubscription)
from src.database.session import get_db
from src.core.notifications import send_event_push
from src.shared.dtos import DataResponse
from src.user.subscriptions.routes import get_settings, payment_data, plan_data, seed_plans

router = APIRouter(prefix="/admin", tags=["admin-subscription-payments"])
QR_DIR = Path("src/private_uploads/payment_qr")

class PlanPayload(BaseModel):
    code: str = Field(min_length=2, max_length=60); name: str = Field(min_length=2, max_length=120)
    description: str = ""; storage_gb: int = Field(ge=1, le=10000); price_paise: int = Field(ge=100)
    billing_days: int = Field(default=365, ge=1, le=3660); features: list[str] = Field(default_factory=list)
    why_purchase: list[str] = Field(default_factory=list); is_premium: bool = False; is_active: bool = True; sort_order: int = 0

class ReviewPayload(BaseModel):
    payment_id: int
    reason: str | None = Field(default=None, max_length=1000)

def settings_data(x: PaymentSetting) -> dict:
    return {"id": x.id, "upi_id": x.upi_id, "receiver_name": x.receiver_name,
        "instructions": x.instructions, "payments_enabled": x.payments_enabled,
        "request_expiry_minutes": x.request_expiry_minutes, "qr_available": bool(x.qr_code_path)}

async def detailed_payment(db: AsyncSession, payment: SubscriptionPayment) -> dict:
    plan, user = await db.get(SubscriptionPlan, payment.plan_id), await db.get(User, payment.user_id)
    return payment_data(payment, plan) | {"user_id": payment.user_id, "user_name": user.full_name,
        "user_email": user.email, "has_screenshot": bool(payment.screenshot_path), "reviewed_at": payment.reviewed_at}

@router.get("/subscriptions/plans", response_model=DataResponse)
async def list_plans(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    await seed_plans(db); rows = (await db.scalars(select(SubscriptionPlan).order_by(SubscriptionPlan.sort_order))).all()
    return DataResponse(message="Plans fetched", data=[plan_data(x) for x in rows])

@router.post("/subscriptions/plans", response_model=DataResponse)
async def create_plan(payload: PlanPayload, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    if await db.scalar(select(SubscriptionPlan.id).where(SubscriptionPlan.code == payload.code)): raise HTTPException(status_code=409, detail="Plan code already exists")
    plan = SubscriptionPlan(**payload.model_dump()); db.add(plan); await db.commit(); await db.refresh(plan)
    return DataResponse(message="Plan created", data=plan_data(plan))

@router.put("/subscriptions/plans/{plan_id}", response_model=DataResponse)
async def update_plan(plan_id: int, payload: PlanPayload, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    plan = await db.get(SubscriptionPlan, plan_id)
    if not plan: raise HTTPException(status_code=404, detail="Plan not found")
    duplicate = await db.scalar(select(SubscriptionPlan.id).where(SubscriptionPlan.code == payload.code, SubscriptionPlan.id != plan_id))
    if duplicate: raise HTTPException(status_code=409, detail="Plan code already exists")
    for key, value in payload.model_dump().items(): setattr(plan, key, value)
    await db.commit(); await db.refresh(plan); return DataResponse(message="Plan updated", data=plan_data(plan))

@router.get("/payment-settings", response_model=DataResponse)
async def payment_settings(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    return DataResponse(message="Payment settings fetched", data=settings_data(await get_settings(db)))

@router.put("/payment-settings", response_model=DataResponse)
async def update_settings(upi_id: str = Form(..., min_length=3, max_length=160), receiver_name: str = Form(..., min_length=2, max_length=160), instructions: str = Form(..., max_length=3000), payments_enabled: bool = Form(...), request_expiry_minutes: int = Form(..., ge=5, le=1440), qr_code: UploadFile | None = File(None), db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    setting = await get_settings(db)
    if "@" not in upi_id: raise HTTPException(status_code=422, detail="Enter a valid UPI ID")
    if qr_code:
        ext = {"image/png": ".png", "image/jpeg": ".jpg", "image/webp": ".webp"}.get(qr_code.content_type or "")
        if not ext: raise HTTPException(status_code=415, detail="QR code must be PNG, JPEG, or WEBP")
        content = await qr_code.read(2 * 1024 * 1024 + 1)
        if len(content) > 2 * 1024 * 1024: raise HTTPException(status_code=413, detail="QR image must be smaller than 2 MB")
        QR_DIR.mkdir(parents=True, exist_ok=True); path = QR_DIR / f"{uuid4().hex}{ext}"; path.write_bytes(content); setting.qr_code_path = str(path)
    setting.upi_id, setting.receiver_name, setting.instructions = upi_id.strip(), receiver_name.strip(), instructions.strip()
    setting.payments_enabled, setting.request_expiry_minutes, setting.updated_by_admin_id = payments_enabled, request_expiry_minutes, admin.id
    await db.commit(); await db.refresh(setting); return DataResponse(message="Payment settings updated", data=settings_data(setting))

@router.get("/payments", response_model=DataResponse)
async def payments(status: PaymentStatus | None = None, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    query = select(SubscriptionPayment)
    if status: query = query.where(SubscriptionPayment.status == status)
    rows = (await db.scalars(query.order_by(SubscriptionPayment.created_at.desc()).limit(500))).all()
    return DataResponse(message="Payments fetched", data=[await detailed_payment(db, x) for x in rows])

@router.get("/payments/{payment_id}/screenshot")
async def screenshot(payment_id: int, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> FileResponse:
    payment = await db.get(SubscriptionPayment, payment_id); path = Path(payment.screenshot_path) if payment and payment.screenshot_path else None
    if not path or not path.is_file(): raise HTTPException(status_code=404, detail="Screenshot not found")
    return FileResponse(path, media_type="image/*", headers={"Cache-Control": "private, no-store"})

@router.post("/payment/approve", response_model=DataResponse)
async def approve(payload: ReviewPayload, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    payment = await db.scalar(select(SubscriptionPayment).where(SubscriptionPayment.id == payload.payment_id).with_for_update())
    if not payment: raise HTTPException(status_code=404, detail="Payment not found")
    if payment.status != PaymentStatus.pending_verification: raise HTTPException(status_code=409, detail=f"Payment is already {payment.status.value}")
    plan = await db.get(SubscriptionPlan, payment.plan_id); now = datetime.utcnow()
    active = (await db.scalars(select(UserSubscription).where(UserSubscription.user_id == payment.user_id, UserSubscription.status == SubscriptionStatus.active).with_for_update())).all()
    for old in active: old.status = SubscriptionStatus.cancelled
    subscription = UserSubscription(user_id=payment.user_id, plan_id=plan.id, payment_id=payment.id, storage_gb=plan.storage_gb, starts_at=now, expires_at=now + timedelta(days=plan.billing_days))
    payment.status, payment.reviewed_at, payment.reviewed_by_admin_id = PaymentStatus.approved, now, admin.id
    db.add(subscription); db.add(PaymentAuditLog(payment_id=payment.id, admin_id=admin.id, action="approved", details={"reason": payload.reason or "Payment verified"}))
    await db.commit(); await db.refresh(subscription)
    await send_event_push(
        db, title="Subscription activated", body=f"Your {plan.name} plan is now active.",
        user_id=payment.user_id, event_type="subscription_activated",
        data={"route": "/subscriptions", "subscription_id": subscription.id},
    )
    return DataResponse(message="Payment approved and subscription activated", data={"subscription_id": subscription.id, "expires_at": subscription.expires_at})

@router.post("/payment/reject", response_model=DataResponse)
async def reject(payload: ReviewPayload, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    reason = (payload.reason or "").strip()
    if len(reason) < 3: raise HTTPException(status_code=422, detail="Rejection reason is required")
    payment = await db.scalar(select(SubscriptionPayment).where(SubscriptionPayment.id == payload.payment_id).with_for_update())
    if not payment: raise HTTPException(status_code=404, detail="Payment not found")
    if payment.status != PaymentStatus.pending_verification: raise HTTPException(status_code=409, detail=f"Payment is already {payment.status.value}")
    payment.status, payment.rejection_reason, payment.reviewed_at, payment.reviewed_by_admin_id = PaymentStatus.rejected, reason, datetime.utcnow(), admin.id
    db.add(PaymentAuditLog(payment_id=payment.id, admin_id=admin.id, action="rejected", details={"reason": reason})); await db.commit()
    await send_event_push(
        db, title="Payment needs attention", body=f"Payment verification failed: {reason}",
        user_id=payment.user_id, event_type="payment_rejected",
        data={"route": "/subscriptions", "payment_id": payment.id},
    )
    return DataResponse(message="Payment rejected", data={"payment_id": payment.id, "status": payment.status.value})

@router.get("/subscriptions/history", response_model=DataResponse)
async def history(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    rows = (await db.scalars(select(UserSubscription).order_by(UserSubscription.created_at.desc()).limit(500))).all()
    return DataResponse(message="Subscription history fetched", data=[{"id": x.id, "user_id": x.user_id, "plan_id": x.plan_id, "payment_id": x.payment_id, "status": x.status.value, "storage_gb": x.storage_gb, "starts_at": x.starts_at, "expires_at": x.expires_at} for x in rows])
