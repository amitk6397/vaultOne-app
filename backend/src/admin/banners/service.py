from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.banners.dtos import BannerResponse, BannerUpdate
from src.config.cloudinary_config import delete_from_cloudinary, public_id_from_url, upload_to_cloudinary
from src.database.models import HomeBanner
from src.shared.dtos import MessageResponse

ALLOWED_IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


class BannerService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

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
    ) -> BannerResponse:
        banner = HomeBanner(
            image=await self._resolve_image(image_url=image_url, image_file=image_file),
            title=title.strip(),
            subtitle=subtitle.strip(),
            cta_label=cta_label.strip(),
            route_name=route_name.strip() if route_name else None,
            is_active=is_active,
        )
        self.db.add(banner)
        await self.db.commit()
        await self.db.refresh(banner)
        return BannerResponse.model_validate(banner)

    async def list_banners(self, *, active_only: bool = False) -> list[BannerResponse]:
        query = select(HomeBanner)
        if active_only:
            query = query.where(HomeBanner.is_active.is_(True))
        query = query.order_by(HomeBanner.updated_at.desc(), HomeBanner.id.desc())
        banners = (await self.db.scalars(query)).all()
        return [BannerResponse.model_validate(banner) for banner in banners]

    async def update_banner(
        self,
        banner_id: int,
        payload: BannerUpdate,
        image_file: UploadFile | None,
    ) -> BannerResponse:
        banner = await self._get_banner(banner_id)
        data = payload.model_dump(exclude_unset=True, exclude_none=True)
        image_url = data.pop("image_url", None)
        if image_url is not None or image_file is not None:
            old_image = banner.image
            banner.image = await self._resolve_image(
                image_url=image_url,
                image_file=image_file,
            )
        for field, value in data.items():
            setattr(banner, field, value.strip() if isinstance(value, str) else value)
        await self.db.commit()
        await self.db.refresh(banner)
        if "old_image" in locals() and old_image and "res.cloudinary.com" in old_image:
            await delete_from_cloudinary(public_id_from_url(old_image))
        return BannerResponse.model_validate(banner)

    async def delete_banner(self, banner_id: int) -> MessageResponse:
        banner = await self._get_banner(banner_id)
        image = banner.image
        await self.db.delete(banner)
        await self.db.commit()
        if image and "res.cloudinary.com" in image:
            await delete_from_cloudinary(public_id_from_url(image))
        return MessageResponse(message="Banner deleted successfully")

    async def _get_banner(self, banner_id: int) -> HomeBanner:
        banner = await self.db.get(HomeBanner, banner_id)
        if not banner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Banner not found")
        return banner

    async def _resolve_image(
        self,
        *,
        image_url: str | None,
        image_file: UploadFile | None,
    ) -> str:
        if image_url and image_file:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Provide either image_url or image_file",
            )
        if image_url:
            return image_url.strip()
        if image_file:
            extension = ALLOWED_IMAGE_TYPES.get(image_file.content_type or "")
            if extension is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Only JPEG, PNG, and WEBP images are allowed",
                )
            result = await upload_to_cloudinary(
                image_file,
                folder="vaultone/admin/banners",
                public_id=uuid4().hex,
                resource_type="image",
            )
            return result["secure_url"]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide image_url or image_file",
        )
