from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import UserPasswordEntry, UserSecureNote
from src.shared.dtos import MessageResponse
from src.user.passwords.dtos import (
    PasswordEntryResponse,
    PasswordEntrySync,
    SecureNoteResponse,
    SecureNoteSync,
)


class UserPasswordService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_passwords(self, user_id: int) -> list[PasswordEntryResponse]:
        result = await self.db.scalars(
            select(UserPasswordEntry)
            .where(UserPasswordEntry.user_id == user_id)
            .order_by(
                UserPasswordEntry.client_updated_at.desc(),
                UserPasswordEntry.updated_at.desc(),
            )
        )
        return [PasswordEntryResponse.model_validate(item) for item in result.all()]

    async def sync_password(
        self,
        user_id: int,
        local_id: str,
        payload: PasswordEntrySync,
    ) -> PasswordEntryResponse:
        record = await self._get_password_by_local_id(user_id, local_id)
        if record is None:
            record = UserPasswordEntry(user_id=user_id, local_id=local_id)
            self.db.add(record)

        record.title = payload.title.strip()
        record.username = payload.username.strip()
        record.password = payload.password
        record.website = payload.website.strip()
        record.category = payload.category
        record.notes = payload.notes
        record.is_favorite = payload.is_favorite
        record.is_archived = payload.is_archived
        record.client_created_at = payload.created_at
        record.client_updated_at = payload.updated_at

        await self.db.commit()
        await self.db.refresh(record)
        return PasswordEntryResponse.model_validate(record)

    async def delete_password(self, user_id: int, local_id: str) -> MessageResponse:
        record = await self._get_password_by_local_id(user_id, local_id)
        if record is not None:
            await self.db.delete(record)
            await self.db.commit()
        return MessageResponse(message="Password deleted successfully")

    async def list_notes(self, user_id: int) -> list[SecureNoteResponse]:
        result = await self.db.scalars(
            select(UserSecureNote)
            .where(UserSecureNote.user_id == user_id)
            .order_by(
                UserSecureNote.client_updated_at.desc(),
                UserSecureNote.updated_at.desc(),
            )
        )
        return [SecureNoteResponse.model_validate(item) for item in result.all()]

    async def sync_note(
        self,
        user_id: int,
        local_id: str,
        payload: SecureNoteSync,
    ) -> SecureNoteResponse:
        record = await self._get_note_by_local_id(user_id, local_id)
        if record is None:
            record = UserSecureNote(user_id=user_id, local_id=local_id)
            self.db.add(record)

        record.title = payload.title.strip()
        record.body = payload.body
        record.is_pinned = payload.is_pinned
        record.client_created_at = payload.created_at
        record.client_updated_at = payload.updated_at

        await self.db.commit()
        await self.db.refresh(record)
        return SecureNoteResponse.model_validate(record)

    async def delete_note(self, user_id: int, local_id: str) -> MessageResponse:
        record = await self._get_note_by_local_id(user_id, local_id)
        if record is not None:
            await self.db.delete(record)
            await self.db.commit()
        return MessageResponse(message="Secure note deleted successfully")

    async def _get_password_by_local_id(
        self,
        user_id: int,
        local_id: str,
    ) -> UserPasswordEntry | None:
        return await self.db.scalar(
            select(UserPasswordEntry).where(
                UserPasswordEntry.user_id == user_id,
                UserPasswordEntry.local_id == local_id,
            )
        )

    async def _get_note_by_local_id(
        self,
        user_id: int,
        local_id: str,
    ) -> UserSecureNote | None:
        return await self.db.scalar(
            select(UserSecureNote).where(
                UserSecureNote.user_id == user_id,
                UserSecureNote.local_id == local_id,
            )
        )
