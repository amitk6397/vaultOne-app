from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.cloudinary_config import delete_from_cloudinary, upload_to_cloudinary
from src.database.models import User, UserVaultFile
from src.shared.dtos import DataResponse
from src.user.files.dtos import UserVaultFileResponse, UserVaultFileUpdate
from src.user.subscriptions.quota import ensure_storage_quota

ALLOWED_EXTENSIONS = {
    "pdf",
    "jpg",
    "jpeg",
    "png",
    "mp4",
    "mov",
    "zip",
    "rar",
    "7z",
    "doc",
    "docx",
    "xls",
    "xlsx",
    "ppt",
    "pptx",
    "txt",
}


class UserFileController:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_files(self, current_user: User) -> DataResponse:
        result = await self.db.scalars(
            select(UserVaultFile)
            .where(UserVaultFile.user_id == current_user.id)
            .order_by(UserVaultFile.updated_at.desc())
        )
        files = [
            UserVaultFileResponse.model_validate(file).model_dump(mode="json")
            for file in result.all()
        ]
        return DataResponse(message="Files fetched successfully", data=files)

    async def upload_file(
        self,
        *,
        file: UploadFile,
        local_id: str,
        file_type: str,
        tags: str,
        is_private: bool,
        is_favorite: bool,
        current_user: User,
    ) -> DataResponse:
        original_name = Path(file.filename or "vault-file").name
        extension = Path(original_name).suffix.lower().lstrip(".")
        if extension and extension not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This file type is not allowed",
            )

        stored_name = f"{uuid4().hex}.{extension}" if extension else uuid4().hex
        await ensure_storage_quota(self.db, current_user.id, file.size or 0)
        result = await upload_to_cloudinary(
            file,
            folder=f"vaultone/users/{current_user.id}/files",
            public_id=stored_name,
            resource_type="raw",
        )
        size = int(result.get("bytes") or file.size or 0)
        try:
            await ensure_storage_quota(self.db, current_user.id, size)
        except Exception:
            await delete_from_cloudinary(result["public_id"], resource_type="raw")
            raise

        record = UserVaultFile(
            user_id=current_user.id,
            original_name=original_name,
            stored_name=stored_name,
            file_path=result["secure_url"],
            extension=extension,
            file_type=file_type,
            size_bytes=size,
            tags=[item.strip() for item in tags.split(",") if item.strip()],
            is_private=is_private,
            is_favorite=is_favorite,
            is_encrypted=True,
        )
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)

        data = UserVaultFileResponse.model_validate(record).model_dump(mode="json")
        data["local_id"] = local_id
        return DataResponse(message="File uploaded successfully", data=data)

    async def update_file(
        self,
        file_id: int,
        payload: UserVaultFileUpdate,
        current_user: User,
    ) -> DataResponse:
        record = await self._get_owned_file(current_user.id, file_id)
        if payload.tags is not None:
            record.tags = payload.tags
        if payload.is_favorite is not None:
            record.is_favorite = payload.is_favorite
        if payload.is_archived is not None:
            record.is_archived = payload.is_archived
        if payload.is_private is not None:
            record.is_private = payload.is_private

        await self.db.commit()
        await self.db.refresh(record)
        return DataResponse(
            message="File updated successfully",
            data=UserVaultFileResponse.model_validate(record).model_dump(mode="json"),
        )

    async def delete_file(self, file_id: int, current_user: User) -> DataResponse:
        record = await self._get_owned_file(current_user.id, file_id)
        public_id = f"vaultone/users/{current_user.id}/files/{record.stored_name}"
        await self.db.delete(record)
        await self.db.commit()
        if "res.cloudinary.com" in record.file_path:
            await delete_from_cloudinary(public_id, resource_type="raw")
        return DataResponse(message="File deleted successfully")

    async def _get_owned_file(self, user_id: int, file_id: int) -> UserVaultFile:
        record = await self.db.scalar(
            select(UserVaultFile).where(
                UserVaultFile.id == file_id,
                UserVaultFile.user_id == user_id,
            )
        )
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found",
            )
        return record
