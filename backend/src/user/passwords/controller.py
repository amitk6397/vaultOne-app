from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User
from src.shared.dtos import DataResponse
from src.user.passwords.dtos import PasswordEntrySync, SecureNoteSync
from src.user.passwords.service import UserPasswordService


class UserPasswordController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = UserPasswordService(db)

    async def list_passwords(self, current_user: User) -> DataResponse:
        passwords = await self.service.list_passwords(current_user.id)
        return DataResponse(message="Passwords fetched successfully", data=passwords)

    async def sync_password(
        self,
        local_id: str,
        payload: PasswordEntrySync,
        current_user: User,
    ) -> DataResponse:
        password = await self.service.sync_password(
            current_user.id,
            local_id,
            payload,
        )
        return DataResponse(message="Password synced successfully", data=password)

    async def delete_password(self, local_id: str, current_user: User) -> DataResponse:
        response = await self.service.delete_password(current_user.id, local_id)
        return DataResponse(message=response.message)

    async def list_notes(self, current_user: User) -> DataResponse:
        notes = await self.service.list_notes(current_user.id)
        return DataResponse(message="Secure notes fetched successfully", data=notes)

    async def sync_note(
        self,
        local_id: str,
        payload: SecureNoteSync,
        current_user: User,
    ) -> DataResponse:
        note = await self.service.sync_note(current_user.id, local_id, payload)
        return DataResponse(message="Secure note synced successfully", data=note)

    async def delete_note(self, local_id: str, current_user: User) -> DataResponse:
        response = await self.service.delete_note(current_user.id, local_id)
        return DataResponse(message=response.message)
