from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from src.database.models import MediaKind, MediaVisibility
from src.shared.dtos import ORMModel


class MediaItemUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    title: str | None = Field(default=None, min_length=1, max_length=255)
    visibility: MediaVisibility | None = None
    album_id: str | None = Field(default=None, alias="albumId", max_length=160)
    album_name: str | None = Field(default=None, alias="albumName", max_length=160)
    folder_name: str | None = Field(default=None, alias="folderName", max_length=160)
    size_mb: float | None = Field(default=None, alias="sizeMb", ge=0)
    duration_seconds: int | None = Field(default=None, alias="durationSeconds", ge=0)
    last_position_seconds: int | None = Field(
        default=None,
        alias="lastPositionSeconds",
        ge=0,
    )
    is_favorite: bool | None = Field(default=None, alias="isFavorite")
    is_hidden: bool | None = Field(default=None, alias="isHidden")
    is_deleted: bool | None = Field(default=None, alias="isDeleted")


class MediaItemResponse(ORMModel):
    id: int
    local_id: str
    title: str
    kind: MediaKind
    visibility: MediaVisibility
    album_id: str
    album_name: str
    folder_name: str
    file_path: str | None
    original_name: str | None
    extension: str
    size_mb: float
    duration_seconds: int | None
    last_position_seconds: int | None
    is_favorite: bool
    is_hidden: bool
    is_deleted: bool
    client_created_at: datetime | None
    created_at: datetime
    updated_at: datetime
