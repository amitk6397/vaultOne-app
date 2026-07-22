import asyncio
import urllib.request
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
import cloudinary.api
from fastapi.responses import FileResponse, Response
from jose import JWTError, jwt
from sqlalchemy import delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.settings import settings
from src.core.notifications import send_event_push
from src.database.models import User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.connect.dtos import (
    CompleteUploadRequest, ContactDiscoverRequest, DirectConversationRequest,
    DisappearingMessagesRequest, InitUploadRequest, ReportRequest, SendMessageRequest,
)
from src.user.connect.models import (
    AttachmentStatus, Conversation, ConversationMember, Message, MessageAttachment,
    MessageReceipt, UserBlock,
)
from src.user.connect.realtime import manager
from src.user.connect.storage import (
    delete_private_object,
    finalize_private_upload,
    is_cloud_key,
    local_relative_key,
)
from src.user.connect.service import (
    attachment_data, check_access, config, conversation_data, create_report,
    delete_message, direct_conversation, discover_contacts, is_blocked,
    list_conversations, list_messages, mark_receipt, message_data,
    unread_message_count,
    other_participant, participant_ids, private_storage_key, require_member,
    safe_filename, send_message, sha256_file, validate_upload, verify_magic,
)

router = APIRouter(tags=["vault-connect"])
STORAGE_ROOT = Path(__file__).resolve().parents[3] / "private_uploads" / "vault_connect"
STORAGE_ROOT.mkdir(parents=True, exist_ok=True)


def _fetch_private_cloud_file(url: str) -> bytes:
    # Keep Cloudinary's authenticated URL server-side. The mobile client only
    # receives a membership-checked, five-minute VaultOne download token.
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


class RateLimiter:
    def __init__(self) -> None:
        self.hits: dict[tuple[str, int], deque] = defaultdict(deque)
        self.lock = asyncio.Lock()

    async def check(self, bucket: str, user_id: int, limit: int, window: int = 60) -> None:
        now = datetime.utcnow().timestamp()
        async with self.lock:
            values = self.hits[(bucket, user_id)]
            while values and values[0] <= now - window:
                values.popleft()
            if len(values) >= limit:
                raise HTTPException(429, "Too many requests")
            values.append(now)


limiter = RateLimiter()


@router.post("/contacts/discover", response_model=DataResponse)
async def contacts_discover(payload: ContactDiscoverRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    cfg = await config(db)
    await limiter.check("contact_discover", user.id, 10, 60)
    if len(payload.phones) > cfg.contact_batch_limit:
        raise HTTPException(413, "Contact batch is too large")
    return DataResponse(message="Registered contacts fetched", data={"matches": await discover_contacts(db, user.id, payload.phones)})


@router.post("/conversations/direct", response_model=DataResponse)
async def create_direct(payload: DirectConversationRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    conversation = await direct_conversation(db, user.id, payload.user_id)
    return DataResponse(message="Direct conversation ready", data=await conversation_data(db, conversation, user.id))


@router.get("/conversations", response_model=DataResponse)
async def conversations(cursor: str | None = None, limit: int = Query(30, ge=1, le=100), db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    return DataResponse(message="Conversations fetched", data=await list_conversations(db, user.id, cursor, limit))


@router.get("/conversations/{conversation_id}", response_model=DataResponse)
async def get_conversation(conversation_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await require_member(db, conversation_id, user.id)
    item = await db.get(Conversation, conversation_id)
    return DataResponse(message="Conversation fetched", data=await conversation_data(db, item, user.id))


@router.get("/conversations/{conversation_id}/messages", response_model=DataResponse)
async def messages(conversation_id: str, cursor: str | None = None, limit: int = Query(50, ge=1, le=100), db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    return DataResponse(message="Messages fetched", data=await list_messages(db, conversation_id, user.id, cursor, limit))


@router.patch("/conversations/{conversation_id}/disappearing-messages", response_model=DataResponse)
async def disappearing(conversation_id: str, payload: DisappearingMessagesRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await require_member(db, conversation_id, user.id)
    item = await db.get(Conversation, conversation_id)
    item.disappearing_duration_seconds = payload.duration_seconds or None
    await db.commit()
    users = await participant_ids(db, conversation_id)
    await manager.emit_conversation(conversation_id, users, "conversation.updated", {"conversation_id": conversation_id, "disappearing_duration_seconds": payload.duration_seconds})
    return DataResponse(message="Disappearing messages updated", data={"duration_seconds": payload.duration_seconds})


@router.delete("/conversations/{conversation_id}/clear", response_model=DataResponse)
async def clear_conversation(conversation_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    member = await require_member(db, conversation_id, user.id)
    member.cleared_before = datetime.utcnow()
    await db.commit()
    return DataResponse(message="Conversation cleared", data=None)


@router.post("/messages", response_model=DataResponse)
async def create_message(payload: SendMessageRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    cfg = await config(db)
    await limiter.check("messages", user.id, cfg.message_rate_limit, 60)
    message, recipients = await send_message(db, user.id, payload)
    data = await message_data(db, message, user.id)
    await manager.emit_conversation(message.conversation_id, [user.id, *recipients], "message.created", data)
    await manager.emit_summaries(db, message.conversation_id, [user.id, *recipients])
    for recipient in recipients:
        if (
            not manager.online(recipient)
            and await unread_message_count(db, message.conversation_id, recipient) == 1
        ):
            await send_event_push(db, title="VaultOne", body="You received a secure message", user_id=recipient, event_type="vault_connect_message", data={"type": "VAULT_CONNECT_MESSAGE", "conversationId": message.conversation_id, "messageId": message.id})
    return DataResponse(message="Message sent", data=data)


async def _receipt(message_id: str, read: bool, db: AsyncSession, user: User) -> DataResponse:
    receipt = await mark_receipt(db, message_id, user.id, read)
    message = await db.get(Message, message_id)
    event = "message.read" if read else "message.delivered"
    data = {"message_id": message_id, "user_id": user.id, "delivered_at": receipt.delivered_at, "read_at": receipt.read_at}
    await manager.emit_user(message.sender_user_id, event, data)
    await manager.emit_summaries(db, message.conversation_id, [user.id, message.sender_user_id])
    return DataResponse(message=f"Message {event.split('.')[-1]}", data=data)


@router.post("/messages/{message_id}/delivered", response_model=DataResponse)
async def delivered(message_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    return await _receipt(message_id, False, db, user)


@router.post("/messages/{message_id}/read", response_model=DataResponse)
async def read(message_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    return await _receipt(message_id, True, db, user)


@router.delete("/messages/{message_id}", response_model=DataResponse)
async def remove_message(message_id: str, scope: Literal["me", "everyone"] = "me", db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await delete_message(db, message_id, user.id, scope == "everyone")
    if scope == "everyone":
        attachments = (await db.scalars(select(MessageAttachment).where(
            MessageAttachment.message_id == item.id,
        ))).all()
        for attachment in attachments:
            try:
                await delete_private_object(attachment.storage_key, STORAGE_ROOT)
            except Exception as error:
                print(f"Vault Connect attachment cleanup deferred: {error}")
        users = await participant_ids(db, item.conversation_id)
        await manager.emit_conversation(item.conversation_id, users, "message.deleted", {"message_id": item.id, "conversation_id": item.conversation_id})
    return DataResponse(message="Message deleted", data={"id": item.id, "scope": scope})


@router.post("/attachments/init-upload", response_model=DataResponse)
async def init_upload(payload: InitUploadRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await check_access(db, user.id)
    await require_member(db, payload.conversation_id, user.id)
    other = await other_participant(db, payload.conversation_id, user.id)
    if await is_blocked(db, user.id, other):
        raise HTTPException(403, "Messaging is unavailable")
    await validate_upload(db, payload.file_name, payload.mime_type, payload.file_size, payload.file_type)
    suffix = Path(payload.file_name).suffix
    key = private_storage_key(user.id, suffix)
    item = MessageAttachment(
        owner_user_id=user.id, conversation_id=payload.conversation_id,
        storage_key=key, file_name=safe_filename(payload.file_name),
        mime_type=payload.mime_type.lower(), file_size=payload.file_size,
        file_type=payload.file_type, checksum=payload.checksum,
        upload_status=AttachmentStatus.pending,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return DataResponse(message="Upload initialized", data={**attachment_data(item), "upload_url": f"/api/v1/attachments/{item.id}/content", "upload_method": "PUT"})


@router.put("/attachments/{attachment_id}/content", response_model=DataResponse)
async def upload_content(attachment_id: str, upload: UploadFile = File(...), db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await db.get(MessageAttachment, attachment_id)
    if not item or item.owner_user_id != user.id or item.message_id is not None:
        raise HTTPException(404, "Upload not found")
    if item.upload_status not in {AttachmentStatus.pending, AttachmentStatus.failed}:
        raise HTTPException(409, "Upload is not writable")
    target = STORAGE_ROOT / item.storage_key
    target.parent.mkdir(parents=True, exist_ok=True)
    item.upload_status = AttachmentStatus.uploading
    await db.commit()
    size = 0
    try:
        with target.open("wb") as output:
            while chunk := await upload.read(1024 * 1024):
                size += len(chunk)
                if size > item.file_size:
                    raise HTTPException(413, "Uploaded file exceeds declared size")
                output.write(chunk)
        if size != item.file_size:
            raise HTTPException(422, "Uploaded file size does not match declaration")
        extension = Path(item.file_name).suffix.lower().lstrip(".")
        if not verify_magic(target, extension):
            raise HTTPException(415, "File content does not match its extension")
        actual = sha256_file(target)
        if item.checksum and actual.lower() != item.checksum.lower():
            raise HTTPException(422, "File checksum mismatch")
        item.checksum = actual
        await db.commit()
        return DataResponse(message="File uploaded; complete the upload", data={"id": item.id, "checksum": actual})
    except Exception:
        item.upload_status = AttachmentStatus.failed
        await db.commit()
        if target.exists():
            target.unlink()
        raise


@router.post("/attachments/{attachment_id}/complete", response_model=DataResponse)
async def complete_upload(attachment_id: str, payload: CompleteUploadRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await db.get(MessageAttachment, attachment_id)
    if not item or item.owner_user_id != user.id:
        raise HTTPException(404, "Upload not found")
    path = STORAGE_ROOT / item.storage_key
    if not path.is_file() or sha256_file(path).lower() != payload.checksum.lower() or item.checksum != payload.checksum.lower():
        raise HTTPException(422, "Upload checksum verification failed")
    original_key = item.storage_key
    item.storage_key = await finalize_private_upload(path, original_key)
    if is_cloud_key(item.storage_key) and path.is_file():
        path.unlink()
    item.upload_status = AttachmentStatus.complete
    await db.commit()
    return DataResponse(message="Upload completed", data=attachment_data(item))


@router.post("/attachments/{attachment_id}/cancel", response_model=DataResponse)
async def cancel_upload(attachment_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await db.get(MessageAttachment, attachment_id)
    if not item or item.owner_user_id != user.id or item.message_id is not None:
        raise HTTPException(404, "Pending upload not found")
    item.upload_status = AttachmentStatus.cancelled
    item.deleted_at = datetime.utcnow()
    path = STORAGE_ROOT / item.storage_key
    if path.exists():
        path.unlink()
    await db.commit()
    return DataResponse(message="Upload cancelled", data=None)


def _download_token(attachment_id: str, user_id: int) -> str:
    return jwt.encode({"sub": str(user_id), "attachment_id": attachment_id, "purpose": "vault_connect_download", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)}, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


@router.get("/attachments/{attachment_id}/download-url", response_model=DataResponse)
async def download_url(attachment_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await db.get(MessageAttachment, attachment_id)
    if not item or item.upload_status != AttachmentStatus.complete or item.deleted_at:
        raise HTTPException(404, "Attachment not found")
    await require_member(db, item.conversation_id, user.id)
    token = _download_token(attachment_id, user.id)
    return DataResponse(message="Short-lived download URL created", data={"url": f"/api/v1/attachments/{attachment_id}/download?token={token}", "expires_in_seconds": 300, "checksum": item.checksum})


@router.get("/attachments/{attachment_id}/download")
async def download_attachment(attachment_id: str, token: str, db: AsyncSession = Depends(get_db)):
    try:
        claims = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        if claims.get("purpose") != "vault_connect_download" or claims.get("attachment_id") != attachment_id:
            raise ValueError
        user_id = int(claims["sub"])
    except (JWTError, ValueError, KeyError):
        raise HTTPException(401, "Invalid or expired download token")
    item = await db.get(MessageAttachment, attachment_id)
    if not item or item.deleted_at or item.upload_status != AttachmentStatus.complete:
        raise HTTPException(404, "Attachment not found")
    await require_member(db, item.conversation_id, user_id)
    if is_cloud_key(item.storage_key):
        public_id = item.storage_key.removeprefix("cloudinary:")
        try:
            resource = await asyncio.to_thread(
                cloudinary.api.resource,
                public_id,
                resource_type="raw",
                type="authenticated",
            )
            content = await asyncio.to_thread(
                _fetch_private_cloud_file, resource["secure_url"]
            )
        except Exception as error:
            raise HTTPException(
                502, "Secure attachment storage is unavailable"
            ) from error
        return Response(
            content=content,
            media_type=item.mime_type,
            headers={
                "Content-Disposition": (
                    f'attachment; filename="{safe_filename(item.file_name)}"'
                ),
                "Cache-Control": "private, no-store",
            },
        )
    path = STORAGE_ROOT / local_relative_key(item.storage_key)
    if not path.is_file():
        raise HTTPException(410, "Attachment is no longer available")
    return FileResponse(path, media_type=item.mime_type, filename=item.file_name, headers={"Cache-Control": "private, no-store"})


@router.get("/users/blocked", response_model=DataResponse)
async def blocked_users(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    rows = (await db.execute(select(UserBlock, User).join(User, User.id == UserBlock.blocked_user_id).where(UserBlock.blocker_user_id == user.id).order_by(UserBlock.created_at.desc()))).all()
    return DataResponse(message="Blocked users fetched", data=[{**{"block_id": block.id, "created_at": block.created_at}, "user": {"id": target.id, "full_name": target.full_name, "phone": target.phone}} for block, target in rows])


@router.post("/users/{target_id}/block", response_model=DataResponse)
async def block_user(target_id: int, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    if target_id == user.id or not await db.get(User, target_id):
        raise HTTPException(422, "Invalid user")
    existing = await db.scalar(select(UserBlock).where(UserBlock.blocker_user_id == user.id, UserBlock.blocked_user_id == target_id))
    if not existing:
        db.add(UserBlock(blocker_user_id=user.id, blocked_user_id=target_id))
    direct_key = ":".join(map(str, sorted((user.id, target_id))))
    conversation = await db.scalar(select(Conversation).where(Conversation.direct_key == direct_key))
    if conversation:
        pending = (await db.scalars(select(MessageAttachment).where(
            MessageAttachment.conversation_id == conversation.id,
            MessageAttachment.message_id.is_(None),
            MessageAttachment.upload_status.in_([
                AttachmentStatus.pending,
                AttachmentStatus.uploading,
                AttachmentStatus.failed,
            ]),
        ))).all()
        for item in pending:
            item.upload_status, item.deleted_at = AttachmentStatus.cancelled, datetime.utcnow()
            path = STORAGE_ROOT / item.storage_key
            if path.exists():
                path.unlink()
    await db.commit()
    await manager.emit_user(target_id, "user.blocked", {"user_id": user.id})
    return DataResponse(message="User blocked", data={"user_id": target_id})


@router.delete("/users/{target_id}/block", response_model=DataResponse)
async def unblock_user(target_id: int, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    await db.execute(delete(UserBlock).where(UserBlock.blocker_user_id == user.id, UserBlock.blocked_user_id == target_id))
    await db.commit()
    return DataResponse(message="User unblocked", data={"user_id": target_id})


@router.post("/reports", response_model=DataResponse)
async def report(payload: ReportRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    item = await create_report(db, user.id, payload)
    return DataResponse(message="Report submitted", data={"id": item.id, "status": item.status.value, "created_at": item.created_at})
