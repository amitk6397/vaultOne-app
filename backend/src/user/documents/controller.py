from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.cloudinary_config import delete_from_cloudinary, upload_to_cloudinary
from src.database.models import User, UserDigiDocument
from src.shared.dtos import DataResponse
from src.user.documents.dtos import (
    DigiDocumentPatch,
    DigiDocumentResponse,
    DigiDocumentUpsert,
)
from src.user.subscriptions.quota import ensure_storage_quota

ALLOWED_EXTENSIONS = {"pdf", "jpg", "jpeg", "png"}


class UserDigiDocumentController:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_documents(self, current_user: User) -> DataResponse:
        result = await self.db.scalars(
            select(UserDigiDocument)
            .where(UserDigiDocument.user_id == current_user.id)
            .order_by(UserDigiDocument.updated_at.desc())
        )
        data = [
            DigiDocumentResponse.model_validate(item).model_dump(mode="json")
            for item in result.all()
        ]
        return DataResponse(message="Digi documents fetched successfully", data=data)

    async def upsert_document(
        self,
        local_id: str,
        payload: DigiDocumentUpsert,
        current_user: User,
    ) -> DataResponse:
        record = await self._get_by_local_id(current_user.id, local_id)
        if record is None:
            record = UserDigiDocument(user_id=current_user.id, local_id=local_id)
            self.db.add(record)

        self._apply_upsert(record, payload, include_storage_size=False)
        await self.db.commit()
        await self.db.refresh(record)
        return DataResponse(
            message="Digi document synced successfully",
            data=DigiDocumentResponse.model_validate(record).model_dump(mode="json"),
        )

    async def upload_document(
        self,
        *,
        local_id: str,
        payload: DigiDocumentUpsert,
        file: UploadFile,
        current_user: User,
    ) -> DataResponse:
        original_name = Path(file.filename or payload.file_name or "document").name
        extension = Path(original_name).suffix.lower().lstrip(".")
        if extension and extension not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only PDF, JPG, JPEG and PNG documents are allowed",
            )

        stored_name = f"{uuid4().hex}.{extension}" if extension else uuid4().hex

        record = await self._get_by_local_id(current_user.id, local_id)
        replacing_bytes = record.size_bytes if record is not None else 0
        await ensure_storage_quota(self.db, current_user.id, file.size or 0, replacing_bytes)
        result = await upload_to_cloudinary(file, folder=f"vaultone/users/{current_user.id}/documents", public_id=stored_name, resource_type="raw")
        size = int(result.get("bytes") or file.size or 0)
        try:
            await ensure_storage_quota(
                self.db, current_user.id, size, replacing_bytes
            )
        except Exception:
            await delete_from_cloudinary(result["public_id"], resource_type="raw")
            raise

        if record is None:
            record = UserDigiDocument(user_id=current_user.id, local_id=local_id)
            self.db.add(record)

        old_stored_name = record.stored_name
        self._apply_upsert(record, payload, include_storage_size=False)
        record.file_name = original_name
        record.stored_name = stored_name
        record.file_path = result["secure_url"]
        record.extension = extension
        record.size_bytes = size

        await self.db.commit()
        await self.db.refresh(record)
        if old_stored_name and old_stored_name != stored_name:
            await delete_from_cloudinary(f"vaultone/users/{current_user.id}/documents/{old_stored_name}", resource_type="raw")
        return DataResponse(
            message="Digi document uploaded successfully",
            data=DigiDocumentResponse.model_validate(record).model_dump(mode="json"),
        )

    async def patch_document(
        self,
        local_id: str,
        payload: DigiDocumentPatch,
        current_user: User,
    ) -> DataResponse:
        record = await self._get_owned_document(current_user.id, local_id)
        update = payload.model_dump(exclude_unset=True)
        for field, value in update.items():
            setattr(record, field, value)

        await self.db.commit()
        await self.db.refresh(record)
        return DataResponse(
            message="Digi document updated successfully",
            data=DigiDocumentResponse.model_validate(record).model_dump(mode="json"),
        )

    async def delete_document(self, local_id: str, current_user: User) -> DataResponse:
        record = await self._get_owned_document(current_user.id, local_id)
        stored_name = record.stored_name
        cloudinary_file = bool(record.file_path and "res.cloudinary.com" in record.file_path)
        await self.db.delete(record)
        await self.db.commit()
        if stored_name and cloudinary_file:
            await delete_from_cloudinary(f"vaultone/users/{current_user.id}/documents/{stored_name}", resource_type="raw")
        return DataResponse(message="Digi document deleted successfully")

    def _apply_upsert(
        self,
        record: UserDigiDocument,
        payload: DigiDocumentUpsert,
        include_storage_size: bool = False,
    ) -> None:
        record.title = payload.title
        record.file_name = payload.file_name
        record.extension = payload.extension
        # Never trust a device/local file size as cloud usage.
        if include_storage_size:
            record.size_bytes = payload.size_bytes
        record.document_type = payload.document_type
        record.folder_id = payload.folder_id
        record.ocr_text = payload.ocr_text
        record.issuer = payload.issuer
        record.document_number = payload.document_number
        record.extracted_fields = payload.extracted_fields
        record.expiry_date = payload.expiry_date
        record.is_favorite = payload.is_favorite
        record.is_verified = payload.is_verified
        record.client_added_at = payload.client_added_at
        record.client_updated_at = payload.client_updated_at

    async def _get_by_local_id(
        self,
        user_id: int,
        local_id: str,
    ) -> UserDigiDocument | None:
        return await self.db.scalar(
            select(UserDigiDocument).where(
                UserDigiDocument.user_id == user_id,
                UserDigiDocument.local_id == local_id,
            )
        )

    async def _get_owned_document(
        self,
        user_id: int,
        local_id: str,
    ) -> UserDigiDocument:
        record = await self._get_by_local_id(user_id, local_id)
        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Digi document not found",
            )
        return record
