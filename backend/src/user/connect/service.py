from datetime import datetime, timedelta
from pathlib import Path
import hashlib
import re
import secrets

from fastapi import HTTPException
from sqlalchemy import and_, delete, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User
from src.user.connect.dtos import SendMessageRequest
from src.user.connect.models import (
    AttachmentStatus, Conversation, ConversationMember, Message,
    MessageAttachment, MessageReceipt, MessageType, MessageUserState,
    UserBlock, UserReport, VaultConnectConfig, VaultConnectUserAccess,
)

UTC_NOW = datetime.utcnow
DEFAULT_EXTENSIONS = {
    "image": {"jpg", "jpeg", "png", "gif", "webp", "heic"},
    "video": {"mp4", "mov", "m4v", "webm", "3gp"},
    "document": {"pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "csv", "zip"},
    "voice": {"m4a", "aac"},
}
MIME_PREFIX = {"image": "image/", "video": "video/", "voice": "audio/"}
MAGIC = {
    "jpg": (b"\xff\xd8\xff",), "jpeg": (b"\xff\xd8\xff",),
    "png": (b"\x89PNG\r\n\x1a\n",), "gif": (b"GIF87a", b"GIF89a"),
    "pdf": (b"%PDF-",), "zip": (b"PK\x03\x04", b"PK\x05\x06"),
    "mp4": (b"ftyp",), "m4a": (b"ftyp",),
    "aac": (b"\xff\xf1", b"\xff\xf9"), "webp": (b"RIFF",),
}


async def config(db: AsyncSession) -> VaultConnectConfig:
    row = await db.get(VaultConnectConfig, 1)
    if row is None:
        row = VaultConnectConfig(id=1, allowed_extensions=sorted(set().union(*DEFAULT_EXTENSIONS.values())))
        db.add(row)
        try:
            # Persist the singleton immediately. Read-only endpoints also call
            # this helper, so a flush alone would be rolled back when their
            # request-scoped session closes.
            await db.commit()
        except IntegrityError:
            # Two first requests may race to initialize the singleton.
            await db.rollback()
            row = await db.get(VaultConnectConfig, 1)
            if row is None:
                raise
        else:
            # Load server-generated values (notably updated_at) explicitly.
            # Accessing an expired value later would attempt sync lazy I/O and
            # raise MissingGreenlet with AsyncSession.
            await db.refresh(row)
    return row


async def check_access(db: AsyncSession, user_id: int) -> None:
    access = await db.get(VaultConnectUserAccess, user_id)
    if access and (not access.is_enabled or (access.suspended_until and access.suspended_until > UTC_NOW())):
        raise HTTPException(403, "Vault Connect access is disabled")


async def is_blocked(db: AsyncSession, first: int, second: int) -> bool:
    return bool(await db.scalar(select(UserBlock.id).where(or_(
        and_(UserBlock.blocker_user_id == first, UserBlock.blocked_user_id == second),
        and_(UserBlock.blocker_user_id == second, UserBlock.blocked_user_id == first),
    ))))


async def blocked_by(db: AsyncSession, blocker: int, blocked: int) -> bool:
    return bool(await db.scalar(select(UserBlock.id).where(
        UserBlock.blocker_user_id == blocker,
        UserBlock.blocked_user_id == blocked,
    )))


async def require_member(db: AsyncSession, conversation_id: str, user_id: int) -> ConversationMember:
    member = await db.scalar(select(ConversationMember).where(
        ConversationMember.conversation_id == conversation_id,
        ConversationMember.user_id == user_id,
    ))
    if member is None:
        raise HTTPException(404, "Conversation not found")
    return member


async def participant_ids(db: AsyncSession, conversation_id: str) -> list[int]:
    return list((await db.scalars(select(ConversationMember.user_id).where(
        ConversationMember.conversation_id == conversation_id
    ))).all())


async def other_participant(db: AsyncSession, conversation_id: str, user_id: int) -> int:
    other = await db.scalar(select(ConversationMember.user_id).where(
        ConversationMember.conversation_id == conversation_id,
        ConversationMember.user_id != user_id,
    ))
    if other is None:
        raise HTTPException(409, "Direct conversation is incomplete")
    return int(other)


def user_data(user: User) -> dict:
    return {"id": user.id, "full_name": user.full_name, "phone": user.phone}


def attachment_data(item: MessageAttachment) -> dict:
    return {
        "id": item.id, "file_name": item.file_name, "mime_type": item.mime_type,
        "file_size": item.file_size, "file_type": item.file_type,
        "checksum": item.checksum, "upload_status": item.upload_status.value,
        "expires_at": item.expires_at,
    }


async def message_data(db: AsyncSession, item: Message, viewer_id: int) -> dict:
    hidden = await db.scalar(select(MessageUserState.id).where(
        MessageUserState.message_id == item.id,
        MessageUserState.user_id == viewer_id,
        MessageUserState.is_deleted_for_user.is_(True),
    ))
    if hidden:
        return {}
    receipts = (await db.scalars(select(MessageReceipt).where(MessageReceipt.message_id == item.id))).all()
    attachments = (await db.scalars(select(MessageAttachment).where(
        MessageAttachment.message_id == item.id,
        MessageAttachment.deleted_at.is_(None),
    ))).all()
    status = "SENT"
    if item.deleted_at:
        status = "DELETED"
    elif item.expires_at and item.expires_at <= UTC_NOW():
        status = "EXPIRED"
    elif any(x.read_at for x in receipts):
        status = "READ"
    elif any(x.delivered_at for x in receipts):
        status = "DELIVERED"
    return {
        "id": item.id, "client_message_id": item.client_message_id,
        "conversation_id": item.conversation_id, "sender_user_id": item.sender_user_id,
        "message_type": item.message_type.value,
        "content": "This message was deleted" if item.deleted_at else item.content,
        "reply_to_message_id": item.reply_to_message_id,
        "created_at": item.created_at, "deleted_at": item.deleted_at,
        "expires_at": item.expires_at, "status": status,
        "attachments": [attachment_data(x) for x in attachments],
    }


async def conversation_data(db: AsyncSession, conversation: Conversation, viewer_id: int) -> dict:
    member = await require_member(db, conversation.id, viewer_id)
    other_id = await other_participant(db, conversation.id, viewer_id)
    other = await db.get(User, other_id)
    last = await db.get(Message, conversation.last_message_id) if conversation.last_message_id else None
    last_data = await message_data(db, last, viewer_id) if last else None
    unread_query = select(func.count(MessageReceipt.message_id)).join(
        Message, Message.id == MessageReceipt.message_id
    ).where(
        MessageReceipt.user_id == viewer_id,
        MessageReceipt.read_at.is_(None),
        Message.conversation_id == conversation.id,
        Message.sender_user_id != viewer_id,
        Message.deleted_at.is_(None),
    )
    if member.cleared_before:
        unread_query = unread_query.where(Message.created_at > member.cleared_before)
    unread_count = int(await db.scalar(unread_query) or 0)
    return {
        "id": conversation.id, "type": conversation.type.value,
        "participant": user_data(other) if other else {"id": other_id},
        "last_message": last_data or None, "last_message_at": conversation.last_message_at,
        "disappearing_duration_seconds": conversation.disappearing_duration_seconds or 0,
        "is_archived": member.is_archived, "is_muted": member.is_muted,
        "cleared_before": member.cleared_before, "created_at": conversation.created_at,
        "is_blocked": await is_blocked(db, viewer_id, other_id),
        "blocked_by_me": await blocked_by(db, viewer_id, other_id),
        "unread_count": unread_count,
    }


async def unread_message_count(
    db: AsyncSession, conversation_id: str, user_id: int
) -> int:
    """Return authoritative unread messages for push-notification deduping."""
    return int(await db.scalar(
        select(func.count(MessageReceipt.message_id)).join(
            Message, Message.id == MessageReceipt.message_id
        ).where(
            MessageReceipt.user_id == user_id,
            MessageReceipt.read_at.is_(None),
            Message.conversation_id == conversation_id,
            Message.sender_user_id != user_id,
            Message.deleted_at.is_(None),
        )
    ) or 0)


async def discover_contacts(db: AsyncSession, user_id: int, phones: list[str]) -> list[dict]:
    await check_access(db, user_id)
    # Existing VaultOne registrations store digits only. Match the submitted
    # E.164 values against both their full digits and legacy national suffix
    # without persisting the submitted contact batch.
    submitted = {phone: "".join(char for char in phone if char.isdigit()) for phone in phones}
    lookup_values = {
        value
        for digits in submitted.values()
        for value in (digits, digits[-10:])
        if value
    }
    rows = (await db.scalars(select(User).where(
        User.phone.in_(lookup_values), User.id != user_id, User.is_active.is_(True)
    ))).all()
    matches = []
    for row in rows:
        registered = "".join(char for char in row.phone if char.isdigit())
        matched_phone = next(
            (
                phone
                for phone, digits in submitted.items()
                if digits == registered or digits.endswith(registered) or registered.endswith(digits[-10:])
            ),
            row.phone,
        )
        matches.append({**user_data(row), "phone": matched_phone})
    return matches


async def direct_conversation(db: AsyncSession, user_id: int, target_id: int) -> Conversation:
    await check_access(db, user_id)
    if user_id == target_id:
        raise HTTPException(422, "Cannot chat with yourself")
    target = await db.get(User, target_id)
    if not target or not target.is_active:
        raise HTTPException(404, "User not found")
    if await is_blocked(db, user_id, target_id):
        raise HTTPException(403, "Messaging is unavailable")
    key = ":".join(map(str, sorted((user_id, target_id))))
    existing = await db.scalar(select(Conversation).where(Conversation.direct_key == key))
    if existing:
        return existing
    item = Conversation(direct_key=key)
    db.add(item)
    await db.flush()
    db.add_all([
        ConversationMember(conversation_id=item.id, user_id=user_id),
        ConversationMember(conversation_id=item.id, user_id=target_id),
    ])
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        item = await db.scalar(select(Conversation).where(Conversation.direct_key == key))
        if item is None:
            raise
    await db.refresh(item)
    return item


async def list_conversations(db: AsyncSession, user_id: int, cursor: str | None, limit: int) -> dict:
    await check_access(db, user_id)
    query = select(Conversation).join(ConversationMember).where(
        ConversationMember.user_id == user_id, ConversationMember.is_archived.is_(False)
    )
    if cursor:
        anchor = await db.get(Conversation, cursor)
        if anchor:
            anchor_date = anchor.last_message_at or anchor.created_at
            query = query.where((func.coalesce(Conversation.last_message_at, Conversation.created_at) < anchor_date))
    rows = (await db.scalars(query.order_by(
        func.coalesce(Conversation.last_message_at, Conversation.created_at).desc()
    ).limit(limit + 1))).all()
    has_more = len(rows) > limit
    rows = rows[:limit]
    return {"items": [await conversation_data(db, x, user_id) for x in rows], "next_cursor": rows[-1].id if has_more else None}


async def list_messages(db: AsyncSession, conversation_id: str, user_id: int, cursor: str | None, limit: int) -> dict:
    member = await require_member(db, conversation_id, user_id)
    query = select(Message).where(Message.conversation_id == conversation_id)
    if member.cleared_before:
        query = query.where(Message.created_at > member.cleared_before)
    if cursor:
        anchor = await db.get(Message, cursor)
        if anchor and anchor.conversation_id == conversation_id:
            query = query.where(Message.created_at < anchor.created_at)
    rows = (await db.scalars(query.order_by(Message.created_at.desc()).limit(limit + 1))).all()
    visible = []
    for row in rows:
        data = await message_data(db, row, user_id)
        if data:
            visible.append(data)
    has_more = len(rows) > limit
    return {"items": visible[:limit], "next_cursor": rows[min(limit, len(rows)) - 1].id if has_more else None}


async def send_message(db: AsyncSession, user_id: int, payload: SendMessageRequest) -> tuple[Message, list[int]]:
    await check_access(db, user_id)
    await require_member(db, payload.conversation_id, user_id)
    receiver_id = await other_participant(db, payload.conversation_id, user_id)
    if await is_blocked(db, user_id, receiver_id):
        raise HTTPException(403, "Messaging is unavailable")
    duplicate = await db.scalar(select(Message).where(
        Message.sender_user_id == user_id, Message.client_message_id == payload.client_message_id
    ))
    if duplicate:
        return duplicate, [receiver_id]
    if payload.message_type == "text" and not (payload.content or "").strip():
        raise HTTPException(422, "Text message cannot be empty")
    if payload.reply_to_message_id:
        reply = await db.get(Message, payload.reply_to_message_id)
        if not reply or reply.conversation_id != payload.conversation_id:
            raise HTTPException(422, "Invalid reply message")
    convo = await db.get(Conversation, payload.conversation_id)
    expiry = UTC_NOW() + timedelta(seconds=convo.disappearing_duration_seconds) if convo and convo.disappearing_duration_seconds else None
    message = Message(
        client_message_id=payload.client_message_id, conversation_id=payload.conversation_id,
        sender_user_id=user_id, message_type=MessageType(payload.message_type),
        content=(payload.content or "").strip() or None, reply_to_message_id=payload.reply_to_message_id,
        expires_at=expiry,
    )
    db.add(message)
    await db.flush()
    if payload.attachment_ids:
        attachments = (await db.scalars(select(MessageAttachment).where(
            MessageAttachment.id.in_(payload.attachment_ids),
            MessageAttachment.owner_user_id == user_id,
            MessageAttachment.conversation_id == payload.conversation_id,
            MessageAttachment.message_id.is_(None),
            MessageAttachment.upload_status == AttachmentStatus.complete,
        ))).all()
        if len(attachments) != len(set(payload.attachment_ids)):
            raise HTTPException(422, "One or more attachments are invalid")
        for item in attachments:
            item.message_id = message.id
            item.expires_at = expiry
    db.add(MessageReceipt(message_id=message.id, user_id=receiver_id))
    if convo:
        convo.last_message_id, convo.last_message_at = message.id, UTC_NOW()
    await db.commit()
    await db.refresh(message)
    return message, [receiver_id]


async def mark_receipt(db: AsyncSession, message_id: str, user_id: int, read: bool) -> MessageReceipt:
    message = await db.get(Message, message_id)
    if not message:
        raise HTTPException(404, "Message not found")
    await require_member(db, message.conversation_id, user_id)
    if message.sender_user_id == user_id:
        raise HTTPException(422, "Sender cannot acknowledge own message")
    receipt = await db.scalar(select(MessageReceipt).where(
        MessageReceipt.message_id == message_id, MessageReceipt.user_id == user_id
    ))
    if receipt is None:
        receipt = MessageReceipt(message_id=message_id, user_id=user_id)
        db.add(receipt)
    now = UTC_NOW()
    receipt.delivered_at = receipt.delivered_at or now
    if read:
        receipt.read_at = receipt.read_at or now
    await db.commit()
    return receipt


async def delete_message(db: AsyncSession, message_id: str, user_id: int, everyone: bool) -> Message:
    message = await db.get(Message, message_id)
    if not message:
        raise HTTPException(404, "Message not found")
    await require_member(db, message.conversation_id, user_id)
    if not everyone:
        existing = await db.scalar(select(MessageUserState).where(
            MessageUserState.message_id == message_id, MessageUserState.user_id == user_id
        ))
        if existing is None:
            db.add(MessageUserState(message_id=message_id, user_id=user_id))
        await db.commit()
        return message
    if message.sender_user_id != user_id:
        raise HTTPException(403, "Only the sender can delete for everyone")
    cfg = await config(db)
    if UTC_NOW() - message.created_at > timedelta(seconds=cfg.delete_for_everyone_seconds):
        raise HTTPException(403, "Delete-for-everyone window has expired")
    message.content = None
    message.message_type = MessageType.deleted
    message.deleted_at = UTC_NOW()
    for item in (await db.scalars(select(MessageAttachment).where(MessageAttachment.message_id == message.id))).all():
        item.deleted_at = UTC_NOW()
    await db.commit()
    return message


def safe_filename(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9._ -]", "_", Path(value).name)[:255]


async def validate_upload(db: AsyncSession, file_name: str, mime: str, size: int, kind: str) -> None:
    cfg = await config(db)
    limit = {"image": cfg.image_limit_bytes, "video": cfg.video_limit_bytes, "document": cfg.document_limit_bytes, "voice": cfg.document_limit_bytes}[kind]
    extension = Path(file_name).suffix.lower().lstrip(".")
    allowed = set(cfg.allowed_extensions or DEFAULT_EXTENSIONS[kind])
    if size > limit:
        raise HTTPException(413, f"{kind.title()} exceeds the configured size limit")
    if (
        (extension not in allowed and kind != "voice")
        or extension not in DEFAULT_EXTENSIONS[kind]
    ):
        raise HTTPException(415, "File extension is not allowed")
    if kind in MIME_PREFIX and not mime.lower().startswith(MIME_PREFIX[kind]):
        raise HTTPException(415, "MIME type does not match file type")


def verify_magic(path: Path, extension: str) -> bool:
    signatures = MAGIC.get(extension)
    if not signatures:
        return True
    head = path.read_bytes()[:16]
    if extension in {"mp4", "m4a"}:
        return any(x in head for x in signatures)
    if extension == "webp":
        return head.startswith(b"RIFF") and b"WEBP" in head
    return any(head.startswith(x) for x in signatures)


async def create_report(db: AsyncSession, user_id: int, payload) -> UserReport:
    if user_id == payload.reported_user_id:
        raise HTTPException(422, "Cannot report yourself")
    evidence = {}
    if payload.conversation_id:
        await require_member(db, payload.conversation_id, user_id)
    if payload.message_id:
        message = await db.get(Message, payload.message_id)
        if not message or message.conversation_id != payload.conversation_id:
            raise HTTPException(422, "Invalid reported message")
        evidence["message"] = {"id": message.id, "sender_user_id": message.sender_user_id, "message_type": message.message_type.value, "content": message.content, "created_at": message.created_at.isoformat()}
    if payload.attachment_id:
        item = await db.get(MessageAttachment, payload.attachment_id)
        if not item or item.conversation_id != payload.conversation_id:
            raise HTTPException(422, "Invalid reported attachment")
        evidence["attachment"] = {"id": item.id, "file_name": item.file_name, "mime_type": item.mime_type, "checksum": item.checksum}
    report = UserReport(**payload.model_dump(), reporter_user_id=user_id, evidence=evidence)
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def private_storage_key(user_id: int, suffix: str) -> str:
    return f"{user_id}/{secrets.token_urlsafe(24)}{suffix.lower()}"
