from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.banners.controller import UserBannerController

router = APIRouter(prefix="/user/banners", tags=["user-banners"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserBannerController:
    return UserBannerController(db)


@router.get("", response_model=DataResponse)
async def list_active_banners(
    controller: UserBannerController = Depends(get_controller),
) -> DataResponse:
    return await controller.list_active_banners()
