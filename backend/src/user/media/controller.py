from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import MediaKind, MediaVisibility, User
from src.shared.dtos import DataResponse
from src.user.media.dtos import MediaItemUpdate
from src.user.media.service import UserMediaService


class UserMediaController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = UserMediaService(db)

    async def list_media(self, current_user: User) -> DataResponse:
        media = await self.service.list_media(current_user.id)
        return DataResponse(message="Media fetched successfully", data=media)

    async def sync_media(
        self,
        *,
        current_user: User,
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
    ) -> DataResponse:
        media = await self.service.sync_media(
            user_id=current_user.id,
            local_id=local_id,
            title=title,
            kind=kind,
            visibility=visibility,
            album_id=album_id,
            album_name=album_name,
            folder_name=folder_name,
            size_mb=size_mb,
            duration_seconds=duration_seconds,
            last_position_seconds=last_position_seconds,
            is_favorite=is_favorite,
            is_hidden=is_hidden,
            is_deleted=is_deleted,
            client_created_at=client_created_at,
            file=file,
        )
        return DataResponse(message="Media synced successfully", data=media)

    async def update_media(
        self,
        local_id: str,
        payload: MediaItemUpdate,
        current_user: User,
    ) -> DataResponse:
        media = await self.service.update_media(current_user.id, local_id, payload)
        return DataResponse(message="Media updated successfully", data=media)

    async def delete_media(self, local_id: str, current_user: User) -> DataResponse:
        response = await self.service.delete_media(current_user.id, local_id)
        return DataResponse(message=response.message)

    async def get_download(self, local_id: str, current_user: User):
        return await self.service.get_download(current_user.id, local_id)
