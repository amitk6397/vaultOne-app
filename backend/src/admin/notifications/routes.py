from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.core.notifications import send_push
from src.database.models import Admin, PushNotificationLog, User
from src.database.session import get_db
from src.shared.dtos import DataResponse

router = APIRouter(prefix="/admin/notifications", tags=["admin-notifications"])


class SendNotificationPayload(BaseModel):
    title: str = Field(min_length=2, max_length=160)
    body: str = Field(min_length=2, max_length=2000)
    target: str = Field(pattern="^(all|user)$")
    user_id: int | None = None
    route: str | None = Field(default=None, max_length=160)
    data: dict[str, str] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_target(self):
        if self.target == "user" and self.user_id is None:
            raise ValueError("user_id is required for an individual notification")
        return self


@router.post("/send", response_model=DataResponse)
async def send_notification(
    payload: SendNotificationPayload,
    db: AsyncSession = Depends(get_db),
    admin: Admin = Depends(get_current_admin),
) -> DataResponse:
    user_id = payload.user_id if payload.target == "user" else None
    if user_id is not None and not await db.get(User, user_id):
        raise HTTPException(status_code=404, detail="User not found")
    data = payload.data | ({"route": payload.route} if payload.route else {})
    result = await send_push(
        db, title=payload.title, body=payload.body, user_id=user_id,
        data=data, admin_id=admin.id,
    )
    return DataResponse(message="Notification sent", data=result)


@router.get("/history", response_model=DataResponse)
async def notification_history(
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    rows = (await db.scalars(
        select(PushNotificationLog).order_by(PushNotificationLog.created_at.desc()).limit(200)
    )).all()
    return DataResponse(message="Notification history fetched", data=[{
        "id": row.id, "title": row.title, "body": row.body,
        "target_type": row.target_type, "target_user_id": row.target_user_id,
        "success_count": row.success_count, "failure_count": row.failure_count,
        "event_type": row.event_type, "created_at": row.created_at,
    } for row in rows])
