from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.banners.controller import AdminBannerController
from src.admin.dependencies import get_current_admin
from src.database.models import Admin
from src.database.session import get_db
from src.shared.dtos import DataResponse

router = APIRouter(prefix="/admin/banners", tags=["admin-banners"])


def get_controller(db: AsyncSession = Depends(get_db)) -> AdminBannerController:
    return AdminBannerController(db)


@router.post("", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def create_banner(
    title: str = Form(..., min_length=2, max_length=160),
    subtitle: str = Form(..., min_length=2),
    cta_label: str = Form(default="Explore", min_length=2, max_length=80),
    route_name: str | None = Form(default=None, max_length=120),
    image_url: str | None = Form(default=None, max_length=500),
    image_file: UploadFile | None = File(default=None),
    is_active: bool = Form(default=True),
    controller: AdminBannerController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.create_banner(
        title=title,
        subtitle=subtitle,
        cta_label=cta_label,
        route_name=route_name,
        image_url=image_url,
        image_file=image_file,
        is_active=is_active,
    )


@router.get("", response_model=DataResponse)
async def list_banners(
    controller: AdminBannerController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.list_banners()


@router.put("/{banner_id}", response_model=DataResponse)
async def update_banner(
    banner_id: int,
    title: str | None = Form(default=None, min_length=2, max_length=160),
    subtitle: str | None = Form(default=None, min_length=2),
    cta_label: str | None = Form(default=None, min_length=2, max_length=80),
    route_name: str | None = Form(default=None, max_length=120),
    image_url: str | None = Form(default=None, max_length=500),
    image_file: UploadFile | None = File(default=None),
    is_active: bool | None = Form(default=None),
    controller: AdminBannerController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.update_banner(
        banner_id,
        image_url=image_url,
        title=title,
        subtitle=subtitle,
        cta_label=cta_label,
        route_name=route_name,
        image_file=image_file,
        is_active=is_active,
    )


@router.delete("/{banner_id}", response_model=DataResponse)
async def delete_banner(
    banner_id: int,
    controller: AdminBannerController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.delete_banner(banner_id)
