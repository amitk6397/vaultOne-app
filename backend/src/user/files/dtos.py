from datetime import datetime

from pydantic import BaseModel

from src.shared.dtos import ORMModel


class UserVaultFileResponse(ORMModel):
    id: int
    original_name: str
    file_path: str
    extension: str
    file_type: str
    size_bytes: int
    tags: list[str]
    is_favorite: bool
    is_archived: bool
    is_encrypted: bool
    is_private: bool
    created_at: datetime
    updated_at: datetime


class UserVaultFileUpdate(BaseModel):
    tags: list[str] | None = None
    is_favorite: bool | None = None
    is_archived: bool | None = None
    is_private: bool | None = None
