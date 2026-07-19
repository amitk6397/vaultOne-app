from fastapi import HTTPException, status
from sqlalchemy import delete, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.cloudinary_config import delete_from_cloudinary, public_id_from_url
from src.database.models import (
    MediaKind,
    User,
    UserDigiDocument,
    UserMediaItem,
    UserPasswordEntry,
    UserSecureNote,
    UserVaultFile,
)
from src.shared.dtos import DataResponse
from src.user.auth.dtos import UserResponse
from src.user.profile.dtos import UserProfileUpdate


class UserProfileController:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_profile(self, current_user: User) -> DataResponse:
        return DataResponse(
            message="Profile fetched successfully",
            data=UserResponse.model_validate(current_user),
        )

    async def update_profile(
        self,
        payload: UserProfileUpdate,
        current_user: User,
    ) -> DataResponse:
        email = payload.email.lower()
        existing = await self.db.scalar(
            select(User).where(
                User.id != current_user.id,
                or_(User.email == email, User.phone == payload.phone),
            )
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email or phone number already exists",
            )

        current_user.full_name = payload.full_name.strip()
        current_user.email = email
        current_user.phone = payload.phone
        await self.db.commit()
        await self.db.refresh(current_user)

        return DataResponse(
            message="Profile updated successfully",
            data=UserResponse.model_validate(current_user),
        )

    async def delete_data_section(
        self,
        section: str,
        current_user: User,
    ) -> DataResponse:
        user_id = current_user.id
        deleted = 0

        if section == "files":
            records = (await self.db.scalars(
                select(UserVaultFile).where(UserVaultFile.user_id == user_id)
            )).all()
            for record in records:
                if "res.cloudinary.com" in record.file_path:
                    await delete_from_cloudinary(
                        f"vaultone/users/{user_id}/files/{record.stored_name}",
                        resource_type="raw",
                    )
            deleted = len(records)
            await self.db.execute(delete(UserVaultFile).where(UserVaultFile.user_id == user_id))
        elif section == "documents":
            records = (await self.db.scalars(
                select(UserDigiDocument).where(UserDigiDocument.user_id == user_id)
            )).all()
            for record in records:
                if record.stored_name and record.file_path and "res.cloudinary.com" in record.file_path:
                    await delete_from_cloudinary(
                        f"vaultone/users/{user_id}/documents/{record.stored_name}",
                        resource_type="raw",
                    )
            deleted = len(records)
            await self.db.execute(delete(UserDigiDocument).where(UserDigiDocument.user_id == user_id))
        elif section == "passwords":
            password_count = len((await self.db.scalars(select(UserPasswordEntry.id).where(UserPasswordEntry.user_id == user_id))).all())
            note_count = len((await self.db.scalars(select(UserSecureNote.id).where(UserSecureNote.user_id == user_id))).all())
            deleted = password_count + note_count
            await self.db.execute(delete(UserPasswordEntry).where(UserPasswordEntry.user_id == user_id))
            await self.db.execute(delete(UserSecureNote).where(UserSecureNote.user_id == user_id))
        elif section in {"photos", "videos"}:
            kind = MediaKind.photo if section == "photos" else MediaKind.video
            records = (await self.db.scalars(
                select(UserMediaItem).where(UserMediaItem.user_id == user_id, UserMediaItem.kind == kind)
            )).all()
            for record in records:
                if record.file_path and "res.cloudinary.com" in record.file_path:
                    await delete_from_cloudinary(
                        public_id_from_url(record.file_path),
                        resource_type="image" if kind == MediaKind.photo else "video",
                    )
            deleted = len(records)
            await self.db.execute(delete(UserMediaItem).where(UserMediaItem.user_id == user_id, UserMediaItem.kind == kind))
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid data section")

        await self.db.commit()
        return DataResponse(
            message=f"{section.title()} data deleted successfully",
            data={"section": section, "deleted_count": deleted},
        )
