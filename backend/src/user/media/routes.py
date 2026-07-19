from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import MediaKind, MediaVisibility, User, UserMediaItem
from sqlalchemy import select
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.media.controller import UserMediaController
from src.user.media.dtos import MediaItemUpdate
from src.user.subscriptions.quota import ensure_storage_quota

router = APIRouter(prefix="/user/media", tags=["user-media"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserMediaController:
    return UserMediaController(db)


@router.get("", response_model=DataResponse)
async def list_media(
    controller: UserMediaController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.list_media(current_user)


@router.post("", response_model=DataResponse)
async def sync_media(
    local_id: str = Form(...),
    title: str = Form(..., min_length=1, max_length=255),
    kind: MediaKind = Form(...),
    visibility: MediaVisibility = Form(default=MediaVisibility.public),
    album_id: str = Form(default="", max_length=160),
    album_name: str = Form(default="", max_length=160),
    folder_name: str = Form(default="", max_length=160),
    size_mb: float = Form(default=0.0, ge=0),
    duration_seconds: int | None = Form(default=None, ge=0),
    last_position_seconds: int | None = Form(default=None, ge=0),
    is_favorite: bool = Form(default=False),
    is_hidden: bool = Form(default=False),
    is_deleted: bool = Form(default=False),
    client_created_at: str | None = Form(default=None),
    file: UploadFile | None = File(default=None),
    controller: UserMediaController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    if file is not None:
        existing = await db.scalar(select(UserMediaItem).where(UserMediaItem.user_id == current_user.id, UserMediaItem.local_id == local_id))
        await ensure_storage_quota(db, current_user.id, file.size or int(size_mb * 1024 * 1024), int((existing.size_mb if existing else 0) * 1024 * 1024))
    return await controller.sync_media(
        current_user=current_user,
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


@router.patch("/{local_id}", response_model=DataResponse)
async def update_media(
    local_id: str,
    payload: MediaItemUpdate,
    controller: UserMediaController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.update_media(local_id, payload, current_user)


@router.get("/{local_id}/download")
async def download_media(
    local_id: str,
    controller: UserMediaController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> RedirectResponse:
    url, _filename = await controller.get_download(local_id, current_user)
    return RedirectResponse(url=url)


@router.delete("/{local_id}", response_model=DataResponse)
async def delete_media(
    local_id: str,
    controller: UserMediaController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_media(local_id, current_user)
