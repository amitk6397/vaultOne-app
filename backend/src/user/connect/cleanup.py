import asyncio
from datetime import datetime, timedelta
from pathlib import Path

from sqlalchemy import or_, select
from src.database.session import AsyncSessionLocal
from src.user.connect.models import AttachmentStatus, Message, MessageAttachment, MessageType
from src.user.connect.storage import delete_private_object

STORAGE_ROOT = Path(__file__).resolve().parents[3] / "private_uploads" / "vault_connect"


async def cleanup_once() -> dict:
    now = datetime.utcnow()
    expired_count = abandoned_count = 0
    async with AsyncSessionLocal() as db:
        expired = (await db.scalars(select(Message).where(
            Message.expires_at.is_not(None), Message.expires_at <= now, Message.deleted_at.is_(None)
        ).limit(1000))).all()
        for message in expired:
            message.content = None
            message.message_type = MessageType.deleted
            message.deleted_at = now
            expired_count += 1
        attachments = (await db.scalars(select(MessageAttachment).where(or_(
            MessageAttachment.expires_at <= now,
            (
                MessageAttachment.message_id.is_(None)
                & (MessageAttachment.created_at <= now - timedelta(hours=24))
                & MessageAttachment.upload_status.in_([
                    AttachmentStatus.pending, AttachmentStatus.uploading,
                    AttachmentStatus.failed,
                ])
            ),
        )).limit(1000))).all()
        for item in attachments:
            if item.deleted_at is None:
                item.deleted_at = now
                if item.message_id is None:
                    item.upload_status = AttachmentStatus.cancelled
                    abandoned_count += 1
                try:
                    await delete_private_object(item.storage_key, STORAGE_ROOT)
                except Exception as error:
                    print(f"Vault Connect object cleanup deferred: {error}")
        await db.commit()
    return {"expired_messages": expired_count, "abandoned_uploads": abandoned_count, "ran_at": now.isoformat()}


async def cleanup_loop() -> None:
    while True:
        try:
            await cleanup_once()
        except asyncio.CancelledError:
            raise
        except Exception as error:
            print(f"Vault Connect cleanup failed: {error}")
        await asyncio.sleep(900)
