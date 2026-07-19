from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.files.controller import UserFileController
from src.user.files.dtos import UserVaultFileUpdate
from src.user.subscriptions.quota import ensure_storage_quota

router = APIRouter(prefix="/user/files", tags=["user-files"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserFileController:
    return UserFileController(db)


@router.get("", response_model=DataResponse)
async def list_files(
    controller: UserFileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.list_files(current_user)


@router.post("", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def upload_file(
    file: UploadFile = File(...),
    local_id: str = Form(default=""),
    file_type: str = Form(default="other"),
    tags: str = Form(default=""),
    is_private: bool = Form(default=False),
    is_favorite: bool = Form(default=False),
    controller: UserFileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    await ensure_storage_quota(db, current_user.id, file.size or 0)
    return await controller.upload_file(
        file=file,
        local_id=local_id,
        file_type=file_type,
        tags=tags,
        is_private=is_private,
        is_favorite=is_favorite,
        current_user=current_user,
    )


@router.patch("/{file_id}", response_model=DataResponse)
async def update_file(
    file_id: int,
    payload: UserVaultFileUpdate,
    controller: UserFileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.update_file(file_id, payload, current_user)


@router.delete("/{file_id}", response_model=DataResponse)
async def delete_file(
    file_id: int,
    controller: UserFileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_file(file_id, current_user)
