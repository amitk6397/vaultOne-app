from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.auth.controller import AdminAuthController
from src.admin.auth.dtos import (
    AdminForgotPasswordRequest,
    AdminLoginRequest,
    AdminResetPasswordRequest,
    OnboardingSlideUpdate,
)
from src.admin.auth.service import AdminAuthService
from src.admin.dependencies import get_current_admin
from src.database.models import Admin
from src.database.session import get_db
from src.shared.dtos import DataResponse, RefreshTokenRequest, TokenResponse
from src.core.security import create_access_token, create_refresh_token, decode_token

router = APIRouter(prefix="/admin/auth", tags=["admin-auth"])


@router.post("/refresh", response_model=DataResponse)
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    try:
        claims = decode_token(payload.refresh_token)
        if claims.get("token_type") != "refresh" or claims.get("role") != "admin":
            raise ValueError
        admin_id = int(claims["sub"])
    except (JWTError, KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    admin = await db.get(Admin, admin_id)
    if not admin or not admin.is_active:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    return DataResponse(
        message="Token refreshed",
        data=TokenResponse(
            access_token=create_access_token(str(admin_id), claims={"role": "admin"}),
            refresh_token=create_refresh_token(str(admin_id), claims={"role": "admin"}),
        ),
    )


def get_controller(db: AsyncSession = Depends(get_db)) -> AdminAuthController:
    return AdminAuthController(db)


def get_service(db: AsyncSession = Depends(get_db)) -> AdminAuthService:
    return AdminAuthService(db)


@router.post("/login", response_model=DataResponse)
async def login(
    payload: AdminLoginRequest,
    controller: AdminAuthController = Depends(get_controller),
) -> DataResponse:
    token = await controller.login(payload)
    return DataResponse(message="Login successful", data=token)


@router.post("/forgot-password", response_model=DataResponse)
async def forgot_password(
    payload: AdminForgotPasswordRequest,
    controller: AdminAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.forgot_password(payload)
    return DataResponse(message=response.message, data=None)


@router.post("/reset-password", response_model=DataResponse)
async def reset_password(
    payload: AdminResetPasswordRequest,
    controller: AdminAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.reset_password(payload)
    return DataResponse(message=response.message, data=None)


@router.post(
    "/onboarding",
    response_model=DataResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["admin-onboarding"],
)
async def create_onboarding_slide(
    title: str = Form(..., min_length=2, max_length=160),
    subtitle: str = Form(..., min_length=2),
    image_url: str | None = Form(default=None, max_length=500),
    image_file: UploadFile | None = File(default=None),
    is_active: bool = Form(default=True),
    service: AdminAuthService = Depends(get_service),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    slide = await service.create_onboarding_slide(
        title=title,
        subtitle=subtitle,
        image_url=image_url,
        image_file=image_file,
        is_active=is_active,
    )
    return DataResponse(message="Onboarding created successfully", data=slide)


@router.get("/onboarding", response_model=DataResponse, tags=["admin-onboarding"])
async def list_onboarding_slides(
    service: AdminAuthService = Depends(get_service),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    slides = await service.list_onboarding_slides()
    return DataResponse(message="Onboarding fetched successfully", data=slides)


@router.get(
    "/onboarding/{slide_id}",
    response_model=DataResponse,
    tags=["admin-onboarding"],
)
async def get_onboarding_slide(
    slide_id: int,
    service: AdminAuthService = Depends(get_service),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    slide = await service.get_onboarding_slide(slide_id)
    return DataResponse(message="Onboarding fetched successfully", data=slide)


@router.put(
    "/onboarding/{slide_id}",
    response_model=DataResponse,
    tags=["admin-onboarding"],
)
async def update_onboarding_slide(
    slide_id: int,
    title: str | None = Form(default=None, min_length=2, max_length=160),
    subtitle: str | None = Form(default=None, min_length=2),
    image_url: str | None = Form(default=None, max_length=500),
    image_file: UploadFile | None = File(default=None),
    is_active: bool | None = Form(default=None),
    service: AdminAuthService = Depends(get_service),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    payload = OnboardingSlideUpdate(
        image_url=image_url,
        title=title,
        subtitle=subtitle,
        is_active=is_active,
    )
    slide = await service.update_onboarding_slide(slide_id, payload, image_file=image_file)
    return DataResponse(message="Onboarding updated successfully", data=slide)


@router.delete("/onboarding/{slide_id}", response_model=DataResponse, tags=["admin-onboarding"])
async def delete_onboarding_slide(
    slide_id: int,
    service: AdminAuthService = Depends(get_service),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    response = await service.delete_onboarding_slide(slide_id)
    return DataResponse(message=response.message, data=None)
