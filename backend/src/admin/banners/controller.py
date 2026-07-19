from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.banners.dtos import BannerUpdate
from src.admin.banners.service import BannerService
from src.shared.dtos import DataResponse


class AdminBannerController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = BannerService(db)

    async def create_banner(
        self,
        *,
        title: str,
        subtitle: str,
        cta_label: str,
        route_name: str | None,
        image_url: str | None,
        image_file: UploadFile | None,
        is_active: bool,
    ) -> DataResponse:
        banner = await self.service.create_banner(
            title=title,
            subtitle=subtitle,
            cta_label=cta_label,
            route_name=route_name,
            image_url=image_url,
            image_file=image_file,
            is_active=is_active,
        )
        return DataResponse(message="Banner created successfully", data=banner)

    async def list_banners(self) -> DataResponse:
        banners = await self.service.list_banners()
        return DataResponse(message="Banners fetched successfully", data=banners)

    async def update_banner(
        self,
        banner_id: int,
        *,
        title: str | None,
        subtitle: str | None,
        cta_label: str | None,
        route_name: str | None,
        image_url: str | None,
        image_file: UploadFile | None,
        is_active: bool | None,
    ) -> DataResponse:
        banner = await self.service.update_banner(
            banner_id,
            BannerUpdate(
                image_url=image_url,
                title=title,
                subtitle=subtitle,
                cta_label=cta_label,
                route_name=route_name,
                is_active=is_active,
            ),
            image_file=image_file,
        )
        return DataResponse(message="Banner updated successfully", data=banner)

    async def delete_banner(self, banner_id: int) -> DataResponse:
        response = await self.service.delete_banner(banner_id)
        return DataResponse(message=response.message, data=None)
