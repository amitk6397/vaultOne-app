from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.cloudinary_config import delete_from_cloudinary, public_id_from_url, upload_to_cloudinary
from src.database.models import MediaKind, MediaVisibility, UserMediaItem
from src.shared.dtos import MessageResponse
from src.user.media.dtos import MediaItemResponse, MediaItemUpdate
from src.user.subscriptions.quota import ensure_storage_quota

ALLOWED_MEDIA_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "video/mp4": ".mp4",
    "video/quicktime": ".mov",
}
MAX_VIDEO_BYTES = 100 * 1024 * 1024


class UserMediaService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_media(self, user_id: int) -> list[MediaItemResponse]:
        result = await self.db.scalars(
            select(UserMediaItem)
            .where(UserMediaItem.user_id == user_id)
            .order_by(UserMediaItem.updated_at.desc(), UserMediaItem.id.desc())
        )
        return [MediaItemResponse.model_validate(item) for item in result.all()]

    async def sync_media(
        self,
        *,
        user_id: int,
        local_id: str,
        title: str,
        kind: MediaKind,
        visibility: MediaVisibility,
        album_id: str,
        album_name: str,
        folder_name: str,
        size_mb: float,
        duration_seconds: int | None,
        last_position_seconds: int | None,
        is_favorite: bool,
        is_hidden: bool,
        is_deleted: bool,
        client_created_at: str | None,
        file: UploadFile | None,
    ) -> MediaItemResponse:
        record = await self._get_media_by_local_id(user_id, local_id)
        if record is None:
            record = UserMediaItem(user_id=user_id, local_id=local_id, kind=kind)
            self.db.add(record)

        record.title = title.strip()
        record.kind = kind
        record.visibility = visibility
        record.album_id = album_id.strip()
        record.album_name = album_name.strip()
        record.folder_name = folder_name.strip()
        # A device catalog entry is not cloud storage.
        record.size_mb = record.size_mb if record.file_path else 0
        record.duration_seconds = duration_seconds
        record.last_position_seconds = last_position_seconds
        record.is_favorite = is_favorite
        record.is_hidden = is_hidden
        record.is_deleted = is_deleted
        if client_created_at:
            from datetime import datetime

            record.client_created_at = datetime.fromisoformat(
                client_created_at.replace("Z", "+00:00")
            )

        if file is not None:
            incoming = file.size or 0
            replacing = int(record.size_mb * 1024 * 1024) if record.file_path else 0
            await ensure_storage_quota(self.db, user_id, incoming, replacing)
            old_url = record.file_path
            record.file_path, record.original_name, record.extension, written = await self._save_file(
                user_id, file, kind
            )
            try:
                await ensure_storage_quota(self.db, user_id, written, replacing)
            except Exception:
                await delete_from_cloudinary(public_id_from_url(record.file_path), resource_type="video" if kind == MediaKind.video else "image")
                raise
            if old_url and "res.cloudinary.com" in old_url:
                await delete_from_cloudinary(public_id_from_url(old_url), resource_type="video" if kind == MediaKind.video else "image")
            record.size_mb = written / (1024 * 1024)

        await self.db.commit()
        await self.db.refresh(record)
        return MediaItemResponse.model_validate(record)

    async def update_media(
        self,
        user_id: int,
        local_id: str,
        payload: MediaItemUpdate,
    ) -> MediaItemResponse:
        record = await self._get_media_by_local_id(user_id, local_id)
        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Media not found",
            )

        for field, value in payload.model_dump(
            exclude_unset=True,
            by_alias=False,
        ).items():
            setattr(record, field, value.strip() if isinstance(value, str) else value)

        await self.db.commit()
        await self.db.refresh(record)
        return MediaItemResponse.model_validate(record)

    async def delete_media(self, user_id: int, local_id: str) -> MessageResponse:
        record = await self._get_media_by_local_id(user_id, local_id)
        if record is not None:
            file_url = record.file_path
            resource_type = "video" if record.kind == MediaKind.video else "image"
            await self.db.delete(record)
            await self.db.commit()
            if file_url and "res.cloudinary.com" in file_url:
                await delete_from_cloudinary(public_id_from_url(file_url), resource_type=resource_type)
        return MessageResponse(message="Media deleted successfully")

    async def _get_media_by_local_id(
        self,
        user_id: int,
        local_id: str,
    ) -> UserMediaItem | None:
        return await self.db.scalar(
            select(UserMediaItem).where(
                UserMediaItem.user_id == user_id,
                UserMediaItem.local_id == local_id,
            )
        )

    async def _save_file(
        self,
        user_id: int,
        file: UploadFile,
        kind: MediaKind,
    ) -> tuple[str, str, str, int]:
        extension = ALLOWED_MEDIA_TYPES.get(file.content_type or "")
        if extension is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only JPEG, PNG, WEBP, MP4, and MOV media are allowed",
            )

        original_name = Path(file.filename or f"media{extension}").name
        if kind == MediaKind.video and (file.size or 0) > MAX_VIDEO_BYTES:
            raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Video must be smaller than 100 MB")
        result = await upload_to_cloudinary(
            file,
            folder=f"vaultone/users/{user_id}/media",
            public_id=uuid4().hex,
            resource_type="video" if kind == MediaKind.video else "image",
        )
        written = int(result.get("bytes") or file.size or 0)
        return result["secure_url"], original_name, extension, written

    async def get_download(self, user_id: int, local_id: str) -> tuple[str, str]:
        record = await self._get_media_by_local_id(user_id, local_id)
        if record is None or not record.file_path:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Media file not found")
        return record.file_path, record.original_name or record.title
