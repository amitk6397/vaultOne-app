from sqlalchemy.ext.asyncio import AsyncSession

from src.shared.dtos import MessageResponse, TokenResponse
from src.user.auth.dtos import (
    ForgotPasswordRequest,
    LoginRequest,
    RegisterResponse,
    RegisterRequest,
    ResetPasswordRequest,
    ResendOtpRequest,
    UserAuthResponse,
    UserResponse,
    VerifyOtpRequest,
)
from src.user.auth.service import UserAuthService


class UserAuthController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = UserAuthService(db)

    async def register(self, payload: RegisterRequest) -> RegisterResponse:
        return await self.service.register(payload)

    async def login(self, payload: LoginRequest) -> UserAuthResponse:
        return await self.service.login(payload)

    async def forgot_password(self, payload: ForgotPasswordRequest) -> MessageResponse:
        return await self.service.forgot_password(payload)

    async def verify_otp(self, payload: VerifyOtpRequest) -> UserAuthResponse | MessageResponse:
        return await self.service.verify_otp(payload)

    async def reset_password(self, payload: ResetPasswordRequest) -> MessageResponse:
        return await self.service.reset_password(payload)

    async def resend_otp(self, payload: ResendOtpRequest) -> MessageResponse:
        return await self.service.resend_otp(payload)
