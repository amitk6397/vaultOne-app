from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from src.shared.dtos import ORMModel


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class AdminForgotPasswordRequest(BaseModel):
    email: EmailStr


class AdminResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)
    password: str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)


class AdminResponse(ORMModel):
    id: int
    full_name: str
    email: EmailStr
    is_active: bool


class OnboardingSlideResponse(ORMModel):
    id: int
    image: str
    title: str
    subtitle: str
    is_active: bool
    created_at: datetime
    updated_at: datetime


class OnboardingSlideUpdate(BaseModel):
    image_url: str | None = Field(default=None, max_length=500)
    title: str | None = Field(default=None, min_length=2, max_length=160)
    subtitle: str | None = Field(default=None, min_length=2)
    is_active: bool | None = None
