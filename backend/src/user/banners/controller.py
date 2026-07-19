from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.banners.service import BannerService
from src.shared.dtos import DataResponse


class UserBannerController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = BannerService(db)

    async def list_active_banners(self) -> DataResponse:
        banners = await self.service.list_banners(active_only=True)
        return DataResponse(message="Banners fetched successfully", data=banners)
