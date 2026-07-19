from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.passwords.controller import UserPasswordController
from src.user.passwords.dtos import PasswordEntrySync, SecureNoteSync

router = APIRouter(prefix="/user", tags=["user-passwords"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserPasswordController:
    return UserPasswordController(db)


@router.get("/passwords", response_model=DataResponse)
async def list_passwords(
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.list_passwords(current_user)


@router.put("/passwords/{local_id}", response_model=DataResponse)
async def sync_password(
    local_id: str,
    payload: PasswordEntrySync,
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.sync_password(local_id, payload, current_user)


@router.delete("/passwords/{local_id}", response_model=DataResponse)
async def delete_password(
    local_id: str,
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_password(local_id, current_user)


@router.get("/secure-notes", response_model=DataResponse)
async def list_notes(
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.list_notes(current_user)


@router.put("/secure-notes/{local_id}", response_model=DataResponse)
async def sync_note(
    local_id: str,
    payload: SecureNoteSync,
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.sync_note(local_id, payload, current_user)


@router.delete("/secure-notes/{local_id}", response_model=DataResponse)
async def delete_note(
    local_id: str,
    controller: UserPasswordController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_note(local_id, current_user)
