from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from src.database.models import PasswordCategory
from src.shared.dtos import ORMModel


class PasswordEntrySync(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    title: str = Field(min_length=1, max_length=160)
    username: str = Field(min_length=1, max_length=255)
    password: str = Field(min_length=1)
    website: str = Field(default="", max_length=500)
    category: PasswordCategory = PasswordCategory.other
    notes: str = ""
    is_favorite: bool = Field(default=False, alias="isFavorite")
    is_archived: bool = Field(default=False, alias="isArchived")
    created_at: datetime | None = Field(default=None, alias="createdAt")
    updated_at: datetime | None = Field(default=None, alias="updatedAt")


class PasswordEntryResponse(ORMModel):
    id: int
    local_id: str
    title: str
    username: str
    password: str
    website: str
    category: PasswordCategory
    notes: str
    is_favorite: bool
    is_archived: bool
    client_created_at: datetime | None
    client_updated_at: datetime | None
    created_at: datetime
    updated_at: datetime


class SecureNoteSync(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    title: str = Field(min_length=1, max_length=160)
    body: str = Field(min_length=1)
    is_pinned: bool = Field(default=False, alias="isPinned")
    created_at: datetime | None = Field(default=None, alias="createdAt")
    updated_at: datetime | None = Field(default=None, alias="updatedAt")


class SecureNoteResponse(ORMModel):
    id: int
    local_id: str
    title: str
    body: str
    is_pinned: bool
    client_created_at: datetime | None
    client_updated_at: datetime | None
    created_at: datetime
    updated_at: datetime
