from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.session import get_db
from src.shared.dtos import DataResponse, MessageResponse, RefreshTokenRequest, TokenResponse
from src.core.security import create_access_token, create_refresh_token, decode_token
from src.database.models import User, UserAuthEvent, UserAuthEventType, UserTokenState
from src.user.dependencies import get_current_user
from src.user.auth.controller import UserAuthController
from src.user.auth.dtos import (
    ForgotPasswordRequest,
    LoginRequest,
    LoginOtpRequest,
    OnboardingSlideResponse,
    RegisterRequest,
    ResetPasswordRequest,
    ResendOtpRequest,
    UserAuthResponse,
    UserResponse,
    VerifyOtpRequest,
)
from src.user.auth.service import UserAuthService

router = APIRouter(prefix="/user/auth", tags=["user-auth"])


@router.post("/refresh", response_model=DataResponse)
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    try:
        claims = decode_token(payload.refresh_token)
        if claims.get("token_type") != "refresh" or claims.get("role") != "user":
            raise ValueError
        user_id = int(claims["sub"])
    except (JWTError, KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    token_state = await db.get(UserTokenState, user_id)
    session_version = token_state.session_version if token_state else 0
    if int(claims.get("session_version", 0)) != session_version:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    return DataResponse(
        message="Token refreshed",
        data=TokenResponse(
            access_token=create_access_token(
                str(user_id),
                claims={"role": "user", "session_version": session_version},
            ),
            refresh_token=create_refresh_token(
                str(user_id),
                claims={"role": "user", "session_version": session_version},
            ),
        ),
    )


def get_controller(db: AsyncSession = Depends(get_db)) -> UserAuthController:
    return UserAuthController(db)


@router.post("/register", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    user = await controller.register(payload)
    return DataResponse(message="Registration successful", data=user)


@router.post("/login", response_model=DataResponse)
async def login(
    payload: LoginRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    auth = await controller.login(payload)
    return DataResponse(message="Login successful", data=auth)


@router.post("/logout", response_model=DataResponse)
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    db.add(UserAuthEvent(
        user_id=current_user.id,
        event_type=UserAuthEventType.logout,
        auth_method="app",
    ))
    await db.commit()
    return DataResponse(message="Logout recorded", data=None)


@router.post("/login/otp", response_model=DataResponse)
async def send_login_otp(
    payload: LoginOtpRequest,
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    response = await UserAuthService(db).send_login_otp(payload)
    return DataResponse(message=response.message, data={"otp": response.otp})


@router.post("/forgot-password", response_model=DataResponse)
async def forgot_password(
    payload: ForgotPasswordRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.forgot_password(payload)
    return DataResponse(message=response.message, data={"otp": response.otp})


@router.post("/verify-otp", response_model=DataResponse)
async def verify_otp(
    payload: VerifyOtpRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.verify_otp(payload)
    if isinstance(response, MessageResponse):
        return DataResponse(message=response.message, data=None)
    return DataResponse(message="OTP verified successfully", data=response)


@router.post("/reset-password", response_model=DataResponse)
async def reset_password(
    payload: ResetPasswordRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.reset_password(payload)
    return DataResponse(message=response.message, data=None)


@router.post("/resend-otp", response_model=DataResponse)
async def resend_otp(
    payload: ResendOtpRequest,
    controller: UserAuthController = Depends(get_controller),
) -> DataResponse:
    response = await controller.resend_otp(payload)
    return DataResponse(message=response.message, data={"otp": response.otp})


@router.get("/onboarding", response_model=DataResponse, tags=["user-onboarding"])
async def get_onboarding_slides(
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    slides = await UserAuthService(db).list_onboarding_slides()
    return DataResponse(message="Onboarding fetched successfully", data=slides)
