from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.profile.controller import UserProfileController
from src.user.profile.dtos import AccountDeletionRequestCreate, UserProfileUpdate

router = APIRouter(prefix="/user/profile", tags=["user-profile"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserProfileController:
    return UserProfileController(db)


@router.get("/me", response_model=DataResponse)
async def get_profile(
    controller: UserProfileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.get_profile(current_user)


@router.put("/me", response_model=DataResponse)
async def update_profile(
    payload: UserProfileUpdate,
    controller: UserProfileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.update_profile(payload, current_user)


@router.delete("/data/{section}", response_model=DataResponse)
async def delete_data_section(
    section: str,
    controller: UserProfileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_data_section(section, current_user)


@router.post("/deletion-request", response_model=DataResponse)
async def request_account_deletion(
    payload: AccountDeletionRequestCreate,
    controller: UserProfileController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.request_account_deletion(payload, current_user)
