from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.auth.dtos import (
    AdminForgotPasswordRequest,
    AdminLoginRequest,
    AdminResetPasswordRequest,
)
from src.admin.auth.service import AdminAuthService
from src.shared.dtos import MessageResponse, TokenResponse


class AdminAuthController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = AdminAuthService(db)

    async def login(self, payload: AdminLoginRequest) -> TokenResponse:
        return await self.service.login(payload)

    async def forgot_password(
        self,
        payload: AdminForgotPasswordRequest,
    ) -> MessageResponse:
        return await self.service.forgot_password(payload)

    async def reset_password(
        self,
        payload: AdminResetPasswordRequest,
    ) -> MessageResponse:
        return await self.service.reset_password(payload)
