from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.dialects.mysql import insert as mysql_insert
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.database.models import Admin, User, UserDeviceToken, UserTokenState
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.connect.cleanup import cleanup_once
from src.user.connect.models import (
    AttachmentStatus, Conversation, Message, MessageAttachment, ReportStatus,
    UserBlock, UserReport, VaultConnectAuditLog, VaultConnectConfig,
    VaultConnectUserAccess,
)
from src.user.connect.service import config
from src.user.connect.realtime import manager

router = APIRouter(prefix="/admin/vault-connect", tags=["admin-vault-connect"])


class ConfigUpdate(BaseModel):
    image_limit_bytes: int | None = Field(default=None, ge=1024, le=1024 * 1024 * 1024)
    video_limit_bytes: int | None = Field(default=None, ge=1024, le=2 * 1024 * 1024 * 1024)
    document_limit_bytes: int | None = Field(default=None, ge=1024, le=1024 * 1024 * 1024)
    contact_batch_limit: int | None = Field(default=None, ge=10, le=1000)
    message_rate_limit: int | None = Field(default=None, ge=1, le=1000)
    delete_for_everyone_seconds: int | None = Field(default=None, ge=60, le=30 * 86400)
    allowed_extensions: list[str] | None = None
    disappearing_durations: list[int] | None = None


class AccessUpdate(BaseModel):
    is_enabled: bool
    suspended_until: datetime | None = None


class ReportUpdate(BaseModel):
    status: Literal["pending", "reviewing", "resolved", "dismissed"]
    admin_notes: str = Field(default="", max_length=4000)


def config_data(row: VaultConnectConfig) -> dict:
    return {
        "image_limit_bytes": row.image_limit_bytes,
        "video_limit_bytes": row.video_limit_bytes,
        "document_limit_bytes": row.document_limit_bytes,
        "contact_batch_limit": row.contact_batch_limit,
        "message_rate_limit": row.message_rate_limit,
        "delete_for_everyone_seconds": row.delete_for_everyone_seconds,
        "allowed_extensions": row.allowed_extensions,
        "disappearing_durations": row.disappearing_durations,
        "updated_at": row.updated_at,
    }


@router.get("/overview", response_model=DataResponse)
async def overview(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    chat_users = int(await db.scalar(select(func.count(func.distinct(Message.sender_user_id)))) or 0)
    conversations = int(await db.scalar(select(func.count(Conversation.id))) or 0)
    messages = int(await db.scalar(select(func.count(Message.id))) or 0)
    files = int(await db.scalar(select(func.count(MessageAttachment.id)).where(MessageAttachment.upload_status == AttachmentStatus.complete)) or 0)
    storage = int(await db.scalar(select(func.coalesce(func.sum(MessageAttachment.file_size), 0)).where(MessageAttachment.upload_status == AttachmentStatus.complete, MessageAttachment.deleted_at.is_(None))) or 0)
    failed = int(await db.scalar(select(func.count(MessageAttachment.id)).where(MessageAttachment.upload_status == AttachmentStatus.failed)) or 0)
    pending_reports = int(await db.scalar(select(func.count(UserReport.id)).where(UserReport.status == ReportStatus.pending)) or 0)
    block_rows = int(await db.scalar(select(func.count(UserBlock.id))) or 0)
    logs = (await db.scalars(select(VaultConnectAuditLog).order_by(VaultConnectAuditLog.created_at.desc()).limit(100))).all()
    return DataResponse(message="Vault Connect overview fetched", data={
        "total_chat_users": chat_users, "conversations_count": conversations,
        "messages_count": messages, "files_shared": files, "storage_usage": storage,
        "failed_uploads": failed, "pending_reports": pending_reports,
        "blocked_user_statistics": {"total_blocks": block_rows},
        "suspicious_activity_logs": [{"id": x.id, "user_id": x.user_id, "event_type": x.event_type, "metadata": x.metadata_json, "created_at": x.created_at} for x in logs],
    })


@router.get("/config", response_model=DataResponse)
async def get_config(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    return DataResponse(message="Vault Connect configuration fetched", data=config_data(await config(db)))


@router.patch("/config", response_model=DataResponse)
async def update_config(payload: ConfigUpdate, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    row = await config(db)
    changes = payload.model_dump(exclude_none=True)
    if "allowed_extensions" in changes:
        changes["allowed_extensions"] = sorted({x.lower().lstrip(".") for x in changes["allowed_extensions"] if x.strip()})
    if "disappearing_durations" in changes and 0 not in changes["disappearing_durations"]:
        raise HTTPException(422, "Disappearing durations must include Off (0)")
    for key, value in changes.items():
        setattr(row, key, value)
    db.add(VaultConnectAuditLog(user_id=None, event_type="admin_config_updated", metadata_json={"admin_id": admin.id, "fields": list(changes)}))
    await db.commit()
    await db.refresh(row)
    return DataResponse(message="Vault Connect configuration updated", data=config_data(row))


@router.get("/reports", response_model=DataResponse)
async def reports(status: str | None = None, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    query = select(UserReport)
    if status:
        try:
            query = query.where(UserReport.status == ReportStatus(status))
        except ValueError:
            raise HTTPException(422, "Invalid report status")
    rows = (await db.scalars(query.order_by(UserReport.created_at.desc()).limit(500))).all()
    return DataResponse(message="Reports fetched", data=[{
        "id": x.id, "reporter_user_id": x.reporter_user_id,
        "reported_user_id": x.reported_user_id, "conversation_id": x.conversation_id,
        "category": x.category, "description": x.description, "evidence": x.evidence,
        "status": x.status.value, "admin_notes": x.admin_notes,
        "created_at": x.created_at, "updated_at": x.updated_at,
    } for x in rows])


@router.patch("/reports/{report_id}", response_model=DataResponse)
async def update_report(report_id: str, payload: ReportUpdate, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    item = await db.get(UserReport, report_id)
    if not item:
        raise HTTPException(404, "Report not found")
    item.status = ReportStatus(payload.status)
    item.admin_notes = payload.admin_notes
    db.add(VaultConnectAuditLog(user_id=None, event_type="report_updated", metadata_json={"admin_id": admin.id, "report_id": report_id, "status": payload.status}))
    await db.commit()
    return DataResponse(message="Report updated", data={"id": item.id, "status": item.status.value})


@router.patch("/users/{user_id}/access", response_model=DataResponse)
async def set_access(user_id: int, payload: AccessUpdate, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    if not await db.get(User, user_id):
        raise HTTPException(404, "User not found")
    statement = mysql_insert(VaultConnectUserAccess).values(
        user_id=user_id,
        is_enabled=payload.is_enabled,
        suspended_until=payload.suspended_until,
    )
    statement = statement.on_duplicate_key_update(
        is_enabled=payload.is_enabled,
        suspended_until=payload.suspended_until,
    )
    await db.execute(statement)
    db.add(VaultConnectAuditLog(user_id=user_id, event_type="chat_access_updated", metadata_json={"admin_id": admin.id, "enabled": payload.is_enabled}))
    await db.commit()
    return DataResponse(message="User chat access updated", data={"user_id": user_id, "is_enabled": payload.is_enabled, "suspended_until": payload.suspended_until})


@router.get("/users", response_model=DataResponse)
async def access_users(
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    rows = (
        await db.execute(
            select(User, VaultConnectUserAccess)
            .outerjoin(VaultConnectUserAccess, VaultConnectUserAccess.user_id == User.id)
            .order_by(User.full_name.asc(), User.id.asc())
        )
    ).all()
    return DataResponse(message="Vault Connect user access fetched", data=[
        {
            "id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "phone": user.phone,
            "is_enabled": access.is_enabled if access else True,
            "suspended_until": access.suspended_until if access else None,
        }
        for user, access in rows
    ])


@router.post("/users/{user_id}/revoke-sessions", response_model=DataResponse)
async def revoke_sessions(user_id: int, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    if not await db.get(User, user_id):
        raise HTTPException(404, "User not found")
    rows = (await db.scalars(select(UserDeviceToken).where(UserDeviceToken.user_id == user_id, UserDeviceToken.is_active.is_(True)))).all()
    for row in rows:
        row.is_active = False
    token_state = await db.get(UserTokenState, user_id)
    if token_state is None:
        token_state = UserTokenState(user_id=user_id, session_version=1)
        db.add(token_state)
    else:
        token_state.session_version += 1
    token_state.revoked_at = datetime.utcnow()
    db.add(VaultConnectAuditLog(
        user_id=user_id,
        event_type="device_sessions_revoked",
        metadata_json={
            "admin_id": admin.id,
            "device_tokens": len(rows),
            "session_version": token_state.session_version,
        },
    ))
    await db.commit()
    await manager.disconnect_user(user_id)
    return DataResponse(
        message="Device sessions revoked",
        data={
            "revoked_device_tokens": len(rows),
            "session_version": token_state.session_version,
        },
    )


@router.post("/cleanup/run", response_model=DataResponse)
async def run_cleanup(_: Admin = Depends(get_current_admin)) -> DataResponse:
    return DataResponse(message="Vault Connect cleanup completed", data=await cleanup_once())
