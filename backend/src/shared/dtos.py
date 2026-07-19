from typing import Any

from pydantic import BaseModel, ConfigDict


class MessageResponse(BaseModel):
    message: str
    otp: str | None = None


class DataResponse(BaseModel):
    success: bool = True
    message: str
    data: Any = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)
