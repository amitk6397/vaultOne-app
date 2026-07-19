from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator

from src.database.models import OtpPurpose
from src.shared.dtos import ORMModel


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=3, max_length=120)
    email: EmailStr
    phone: str = Field(min_length=10, max_length=20)
    password: str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)
    terms_accepted: bool

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str) -> str:
        digits = "".join(char for char in value if char.isdigit())
        if len(digits) < 10 or len(digits) > 13:
            raise ValueError("Enter a valid phone number")
        return digits

    @field_validator("password")
    @classmethod
    def validate_strong_password(cls, value: str) -> str:
        checks = [
            any(char.isupper() for char in value),
            any(char.isdigit() for char in value),
            any(not char.isalnum() for char in value),
        ]
        if not all(checks):
            raise ValueError("Use 8+ chars with uppercase, number, and symbol")
        return value

    @model_validator(mode="after")
    def validate_registration(self) -> "RegisterRequest":
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        if not self.terms_accepted:
            raise ValueError("Terms of Service and Privacy Policy must be accepted")
        return self


class LoginRequest(BaseModel):
    identity: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=8)
    remember_me: bool = False


class LoginOtpRequest(BaseModel):
    email: EmailStr


class ForgotPasswordRequest(BaseModel):
    identity: str = Field(min_length=3, max_length=255)


class ResetPasswordRequest(BaseModel):
    identity: str = Field(min_length=3, max_length=255)
    otp: str = Field(min_length=6, max_length=6)
    password: str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)

    @model_validator(mode="after")
    def validate_passwords(self) -> "ResetPasswordRequest":
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        checks = [
            any(char.isupper() for char in self.password),
            any(char.isdigit() for char in self.password),
            any(not char.isalnum() for char in self.password),
        ]
        if not all(checks):
            raise ValueError("Use 8+ chars with uppercase, number, and symbol")
        return self


class VerifyOtpRequest(BaseModel):
    identity: str = Field(min_length=3, max_length=255)
    otp: str = Field(min_length=6, max_length=6)
    purpose: OtpPurpose


class ResendOtpRequest(BaseModel):
    identity: str = Field(min_length=3, max_length=255)
    purpose: OtpPurpose


class UserResponse(ORMModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    is_active: bool
    is_verified: bool


class RegisterResponse(BaseModel):
    user: UserResponse
    otp: str | None = None
    message: str = "Registration successful"


class UserAuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
    message: str = "Authentication successful"


class OnboardingSlideResponse(ORMModel):
    id: int
    image: str
    title: str
    subtitle: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
