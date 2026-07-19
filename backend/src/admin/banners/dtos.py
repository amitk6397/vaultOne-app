from datetime import datetime

from pydantic import BaseModel, Field

from src.shared.dtos import ORMModel


class BannerResponse(ORMModel):
    id: int
    image: str
    title: str
    subtitle: str
    cta_label: str
    route_name: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime


class BannerUpdate(BaseModel):
    image_url: str | None = Field(default=None, max_length=500)
    title: str | None = Field(default=None, min_length=2, max_length=160)
    subtitle: str | None = Field(default=None, min_length=2)
    cta_label: str | None = Field(default=None, min_length=2, max_length=80)
    route_name: str | None = Field(default=None, max_length=120)
    is_active: bool | None = None
