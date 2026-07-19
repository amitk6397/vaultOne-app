from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User, UserDeviceToken, UserNotification
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user

router = APIRouter(prefix="/user/notifications", tags=["user-notifications"])


class DeviceTokenPayload(BaseModel):
    token: str = Field(min_length=20, max_length=512)
    platform: str = Field(default="android", pattern="^(android|ios|web)$")
    device_id: str | None = Field(default=None, max_length=160)


def notification_data(item: UserNotification) -> dict:
    return {
        "id": item.id, "title": item.title, "body": item.body,
        "data": item.data, "event_type": item.event_type,
        "is_read": item.is_read, "read_at": item.read_at,
        "created_at": item.created_at,
    }


@router.get("", response_model=DataResponse)
async def list_notifications(
    limit: int = 100,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    limit = max(1, min(limit, 200))
    offset = max(0, offset)
    rows = (await db.scalars(
        select(UserNotification)
        .where(UserNotification.user_id == user.id)
        .order_by(UserNotification.created_at.desc())
        .offset(offset).limit(limit)
    )).all()
    return DataResponse(message="Notifications fetched", data=[notification_data(x) for x in rows])


@router.get("/count", response_model=DataResponse)
async def unread_count(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    count = await db.scalar(select(func.count()).select_from(UserNotification).where(
        UserNotification.user_id == user.id, UserNotification.is_read.is_(False)
    ))
    return DataResponse(message="Unread notification count fetched", data={"unread_count": count or 0})


@router.get("/{notification_id}", response_model=DataResponse)
async def get_notification(
    notification_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    item = await db.scalar(select(UserNotification).where(
        UserNotification.id == notification_id, UserNotification.user_id == user.id
    ))
    if not item:
        raise HTTPException(status_code=404, detail="Notification not found")
    return DataResponse(message="Notification fetched", data=notification_data(item))


@router.patch("/read-all", response_model=DataResponse)
async def read_all_notifications(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    result = await db.execute(update(UserNotification).where(
        UserNotification.user_id == user.id, UserNotification.is_read.is_(False)
    ).values(is_read=True, read_at=datetime.utcnow()))
    await db.commit()
    return DataResponse(message="All notifications marked as read", data={"updated_count": result.rowcount})


@router.patch("/{notification_id}/read", response_model=DataResponse)
async def read_notification(
    notification_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    item = await db.scalar(select(UserNotification).where(
        UserNotification.id == notification_id, UserNotification.user_id == user.id
    ))
    if not item:
        raise HTTPException(status_code=404, detail="Notification not found")
    if not item.is_read:
        item.is_read, item.read_at = True, datetime.utcnow()
        await db.commit()
    return DataResponse(message="Notification marked as read", data=notification_data(item))


@router.delete("/all", response_model=DataResponse)
async def delete_all_notifications(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    result = await db.execute(delete(UserNotification).where(UserNotification.user_id == user.id))
    await db.commit()
    return DataResponse(message="All notifications deleted", data={"deleted_count": result.rowcount})


@router.delete("/{notification_id}", response_model=DataResponse)
async def delete_notification(
    notification_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    result = await db.execute(delete(UserNotification).where(
        UserNotification.id == notification_id, UserNotification.user_id == user.id
    ))
    if not result.rowcount:
        raise HTTPException(status_code=404, detail="Notification not found")
    await db.commit()
    return DataResponse(message="Notification deleted")


@router.post("/device-token", response_model=DataResponse)
async def register_device_token(
    payload: DeviceTokenPayload,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    token = await db.scalar(
        select(UserDeviceToken).where(UserDeviceToken.token == payload.token)
    )
    if token is None:
        token = UserDeviceToken(user_id=user.id, **payload.model_dump())
        db.add(token)
    else:
        token.user_id = user.id
        token.platform = payload.platform
        token.device_id = payload.device_id
        token.is_active = True
        token.last_seen_at = datetime.utcnow()
    await db.commit()
    return DataResponse(message="Notification device registered", data={"id": token.id})


@router.post("/device-token/unregister", response_model=DataResponse)
async def unregister_device_token(
    payload: DeviceTokenPayload,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DataResponse:
    token = await db.scalar(select(UserDeviceToken).where(
        UserDeviceToken.token == payload.token, UserDeviceToken.user_id == user.id
    ))
    if token:
        token.is_active = False
        await db.commit()
    return DataResponse(message="Notification device unregistered")
