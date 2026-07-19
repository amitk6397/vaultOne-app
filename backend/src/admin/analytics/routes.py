from datetime import datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.database.models import (
    Admin, SubscriptionPlan, User, UserDigiDocument, UserMediaItem,
    UserOffer, UserPasswordEntry, UserSecureNote, UserVaultFile,
    UserAuthEvent, UserAuthEventType,
)
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.subscriptions.quota import storage_status

router = APIRouter(prefix="/admin", tags=["admin-storage-analytics"])


class StorageLimitPayload(BaseModel):
    limit_mb: int | None = Field(default=None, ge=1, le=10 * 1024 * 1024)


class OfferPayload(BaseModel):
    user_id: int
    plan_id: int | None = None
    title: str = Field(min_length=2, max_length=160)
    description: str = Field(default="", max_length=3000)
    discount_percent: int = Field(default=0, ge=0, le=100)
    offer_price_paise: int | None = Field(default=None, ge=0)
    starts_at: datetime | None = None
    expires_at: datetime


def offer_data(offer: UserOffer) -> dict:
    return {
        "id": offer.id, "user_id": offer.user_id, "plan_id": offer.plan_id,
        "title": offer.title, "description": offer.description,
        "discount_percent": offer.discount_percent,
        "offer_price_paise": offer.offer_price_paise,
        "is_active": offer.is_active, "starts_at": offer.starts_at,
        "expires_at": offer.expires_at, "created_at": offer.created_at,
    }


async def _grouped(db: AsyncSession, model, value) -> dict[int, float]:
    rows = (await db.execute(select(model.user_id, func.coalesce(func.sum(value), 0)).group_by(model.user_id))).all()
    return {int(user_id): float(total or 0) for user_id, total in rows}


async def _counts(db: AsyncSession, model) -> dict[int, int]:
    rows = (await db.execute(select(model.user_id, func.count(model.id)).group_by(model.user_id))).all()
    return {int(user_id): int(total) for user_id, total in rows}


async def analytics_rows(db: AsyncSession) -> list[dict]:
    users = (await db.scalars(select(User).order_by(User.created_at.desc()))).all()
    file_bytes = await _grouped(db, UserVaultFile, UserVaultFile.size_bytes)
    document_bytes = await _grouped(db, UserDigiDocument, UserDigiDocument.size_bytes)
    media_mb_rows = (await db.execute(select(UserMediaItem.user_id, func.coalesce(func.sum(UserMediaItem.size_mb), 0)).where(UserMediaItem.file_path.is_not(None)).group_by(UserMediaItem.user_id))).all()
    media_bytes = {int(uid): int(float(total or 0) * 1024 * 1024) for uid, total in media_mb_rows}
    modules = {
        "files": await _counts(db, UserVaultFile),
        "documents": await _counts(db, UserDigiDocument),
        "media": await _counts(db, UserMediaItem),
        "passwords": await _counts(db, UserPasswordEntry),
        "secure_notes": await _counts(db, UserSecureNote),
    }
    result = []
    for user in users:
        entitlement = await storage_status(db, user.id)
        module_bytes = {
            "files": int(file_bytes.get(user.id, 0)),
            "documents": int(document_bytes.get(user.id, 0)),
            "media": int(media_bytes.get(user.id, 0)),
        }
        result.append({
            "user": {"id": user.id, "full_name": user.full_name, "email": user.email, "phone": user.phone, "is_active": user.is_active},
            "used_bytes": entitlement["used_bytes"], "limit_bytes": entitlement["limit_bytes"],
            "usage_percent": entitlement["usage_percent"], "limit_source": entitlement["source"],
            "is_limit_reached": entitlement["is_limit_reached"],
            "module_bytes": module_bytes,
            "module_counts": {key: values.get(user.id, 0) for key, values in modules.items()},
        })
    return result


PERIODS = {
    "day": {"delta": timedelta(hours=23), "format": "%Y-%m-%d %H:00:00", "step": "hour", "points": 24},
    "week": {"delta": timedelta(days=6), "format": "%Y-%m-%d", "step": "day", "points": 7},
    "month": {"delta": timedelta(days=29), "format": "%Y-%m-%d", "step": "day", "points": 30},
    "year": {"delta": None, "format": "%Y-%m-01", "step": "month", "points": 12},
}


def _period_buckets(period: str) -> tuple[datetime, list[tuple[str, str]]]:
    now = datetime.utcnow().replace(minute=0, second=0, microsecond=0)
    config = PERIODS[period]
    if period == "year":
        cursor = now.replace(day=1, hour=0)
        buckets = []
        for offset in range(11, -1, -1):
            year, month = cursor.year, cursor.month - offset
            while month <= 0:
                year -= 1; month += 12
            point = datetime(year, month, 1)
            buckets.append((point.strftime("%Y-%m-01"), point.strftime("%b %Y")))
        return datetime.fromisoformat(buckets[0][0]), buckets
    start = now - config["delta"]
    if period != "day":
        start = start.replace(hour=0)
    buckets = []
    for index in range(config["points"]):
        point = start + (timedelta(hours=index) if period == "day" else timedelta(days=index))
        key = point.strftime(config["format"])
        label = point.strftime("%H:00") if period == "day" else point.strftime("%d %b")
        buckets.append((key, label))
    return start, buckets


async def _timeline_counts(db: AsyncSession, model, start: datetime, date_format: str) -> dict[str, int]:
    bucket = func.date_format(model.created_at, date_format)
    rows = (await db.execute(
        select(bucket, func.count(model.id))
        .where(model.created_at >= start)
        .group_by(bucket)
        .order_by(bucket)
    )).all()
    return {str(key): int(value) for key, value in rows}


@router.get("/analytics/overview", response_model=DataResponse)
async def overview_analytics(
    period: Literal["day", "week", "month", "year"] = "week",
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    start, buckets = _period_buckets(period)
    date_format = PERIODS[period]["format"]
    models = {
        "files": UserVaultFile, "documents": UserDigiDocument,
        "media": UserMediaItem, "passwords": UserPasswordEntry,
        "secure_notes": UserSecureNote,
    }
    user_counts = await _timeline_counts(db, User, start, date_format)
    auth_bucket = func.date_format(UserAuthEvent.created_at, date_format)
    auth_rows = (await db.execute(
        select(auth_bucket, UserAuthEvent.event_type, func.count(UserAuthEvent.id))
        .where(UserAuthEvent.created_at >= start)
        .group_by(auth_bucket, UserAuthEvent.event_type)
    )).all()
    auth_counts: dict[str, dict[str, int]] = {}
    for key, event_type, count in auth_rows:
        event_name = event_type.value if hasattr(event_type, "value") else str(event_type)
        auth_counts.setdefault(str(key), {})[event_name] = int(count)
    module_counts = {
        name: await _timeline_counts(db, model, start, date_format)
        for name, model in models.items()
    }
    total_users = int(await db.scalar(select(func.count(User.id))) or 0)
    active_users = int(await db.scalar(select(func.count(User.id)).where(User.is_active.is_(True))) or 0)
    verified_users = int(await db.scalar(select(func.count(User.id)).where(User.is_verified.is_(True))) or 0)
    module_totals = {
        name: int(await db.scalar(select(func.count(model.id))) or 0)
        for name, model in models.items()
    }
    points = [{
        "key": key, "label": label,
        "users_registered": user_counts.get(key, 0),
        "auth": auth_counts.get(key, {"login": 0, "logout": 0}),
        "modules": {name: counts.get(key, 0) for name, counts in module_counts.items()},
    } for key, label in buckets]
    return DataResponse(message="Live user overview fetched", data={
        "period": period, "generated_at": datetime.utcnow(),
        "summary": {
            "total_users": total_users, "active_users": active_users,
            "blocked_users": total_users - active_users,
            "verified_users": verified_users,
            "new_users": sum(point["users_registered"] for point in points),
            "total_logins": int(await db.scalar(select(func.count(UserAuthEvent.id)).where(UserAuthEvent.event_type == UserAuthEventType.login)) or 0),
            "total_logouts": int(await db.scalar(select(func.count(UserAuthEvent.id)).where(UserAuthEvent.event_type == UserAuthEventType.logout)) or 0),
            "period_logins": sum(point["auth"].get("login", 0) for point in points),
            "period_logouts": sum(point["auth"].get("logout", 0) for point in points),
        },
        "module_totals": module_totals,
        "timeline": points,
    })


@router.get("/analytics/storage", response_model=DataResponse)
async def storage_analytics(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    rows = await analytics_rows(db)
    return DataResponse(message="Live storage analytics fetched", data={
        "summary": {
            "total_users": len(rows),
            "total_used_bytes": sum(x["used_bytes"] for x in rows),
            "users_at_limit": sum(1 for x in rows if x["is_limit_reached"]),
            "users_above_80_percent": sum(1 for x in rows if x["usage_percent"] >= 80),
        },
        "users": rows,
    })


@router.get("/analytics/users/{user_id}", response_model=DataResponse)
async def user_analytics(user_id: int, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    rows = await analytics_rows(db)
    row = next((item for item in rows if item["user"]["id"] == user_id), None)
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
    offers = (await db.scalars(select(UserOffer).where(UserOffer.user_id == user_id).order_by(UserOffer.created_at.desc()))).all()
    row["offers"] = [offer_data(x) for x in offers]
    return DataResponse(message="User analytics fetched", data=row)


@router.patch("/users/{user_id}/storage-limit", response_model=DataResponse)
async def set_storage_limit(user_id: int, payload: StorageLimitPayload, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.storage_limit_bytes = None if payload.limit_mb is None else payload.limit_mb * 1024 * 1024
    await db.commit()
    status_data = await storage_status(db, user_id)
    return DataResponse(message="Storage limit updated", data={"user_id": user_id, "limit_bytes": status_data["limit_bytes"], "source": status_data["source"]})


@router.get("/offers", response_model=DataResponse)
async def list_offers(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    rows = (await db.scalars(select(UserOffer).order_by(UserOffer.created_at.desc()).limit(1000))).all()
    return DataResponse(message="Offers fetched", data=[offer_data(x) for x in rows])


@router.post("/offers", response_model=DataResponse)
async def create_offer(payload: OfferPayload, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    if not await db.get(User, payload.user_id):
        raise HTTPException(status_code=404, detail="User not found")
    if payload.plan_id is not None and not await db.get(SubscriptionPlan, payload.plan_id):
        raise HTTPException(status_code=404, detail="Plan not found")
    starts_at = payload.starts_at or datetime.utcnow()
    if payload.expires_at <= starts_at:
        raise HTTPException(status_code=422, detail="Offer expiry must be after its start")
    offer = UserOffer(**payload.model_dump(exclude={"starts_at"}), starts_at=starts_at, created_by_admin_id=admin.id)
    db.add(offer); await db.commit(); await db.refresh(offer)
    return DataResponse(message="Offer sent to user", data=offer_data(offer))


@router.patch("/offers/{offer_id}/deactivate", response_model=DataResponse)
async def deactivate_offer(offer_id: int, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    offer = await db.get(UserOffer, offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    offer.is_active = False; await db.commit()
    return DataResponse(message="Offer deactivated", data=offer_data(offer))
