from datetime import datetime
from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from src.database.models import (SubscriptionStatus, UserDigiDocument, UserMediaItem,
    User, UserOffer, UserSubscription, UserVaultFile)

FREE_STORAGE_BYTES = 512 * 1024 * 1024

async def storage_usage_bytes(db: AsyncSession, user_id: int) -> int:
    files = int(await db.scalar(select(func.coalesce(func.sum(UserVaultFile.size_bytes), 0)).where(UserVaultFile.user_id == user_id)) or 0)
    documents = int(await db.scalar(select(func.coalesce(func.sum(UserDigiDocument.size_bytes), 0)).where(UserDigiDocument.user_id == user_id)) or 0)
    # Device-only media rows deliberately do not consume cloud quota.
    media_mb = float(await db.scalar(select(func.coalesce(func.sum(UserMediaItem.size_mb), 0)).where(UserMediaItem.user_id == user_id, UserMediaItem.file_path.is_not(None))) or 0)
    return files + documents + int(media_mb * 1024 * 1024)

async def active_subscription(db: AsyncSession, user_id: int) -> UserSubscription | None:
    return await db.scalar(select(UserSubscription).where(
        UserSubscription.user_id == user_id,
        UserSubscription.status == SubscriptionStatus.active,
        UserSubscription.expires_at > datetime.utcnow(),
    ).order_by(UserSubscription.expires_at.desc()))

async def storage_status(db: AsyncSession, user_id: int) -> dict:
    user = await db.get(User, user_id)
    subscription = await active_subscription(db, user_id)
    entitlement = subscription.storage_gb * 1024 * 1024 * 1024 if subscription else FREE_STORAGE_BYTES
    limit = user.storage_limit_bytes if user and user.storage_limit_bytes is not None else entitlement
    used = await storage_usage_bytes(db, user_id)
    now = datetime.utcnow()
    offers = (await db.scalars(select(UserOffer).where(
        UserOffer.user_id == user_id, UserOffer.is_active.is_(True),
        UserOffer.starts_at <= now, UserOffer.expires_at > now,
    ).order_by(UserOffer.created_at.desc()))).all()
    return {
        "used_bytes": used, "limit_bytes": limit,
        "remaining_bytes": max(0, limit - used),
        "usage_percent": round((used / limit * 100) if limit else 100, 2),
        "is_limit_reached": used >= limit,
        "should_show_subscription": subscription is None and used >= limit,
        "source": "admin_override" if user and user.storage_limit_bytes is not None else ("subscription" if subscription else "free"),
        "subscription": subscription,
        "offers": offers,
    }

async def ensure_storage_quota(db: AsyncSession, user_id: int, incoming_bytes: int, replacing_bytes: int = 0) -> None:
    status_data = await storage_status(db, user_id)
    used, limit = status_data["used_bytes"], status_data["limit_bytes"]
    projected = max(0, used - replacing_bytes) + max(0, incoming_bytes)
    if projected > limit:
        raise HTTPException(status_code=413, detail={"code": "STORAGE_LIMIT_REACHED", "message": "Storage limit exceeded", "used_bytes": used, "limit_bytes": limit, "required_bytes": projected, "show_subscription": status_data["subscription"] is None})
