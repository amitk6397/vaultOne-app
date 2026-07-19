from datetime import datetime

from pydantic import BaseModel, Field

from src.shared.dtos import ORMModel


class DigiDocumentUpsert(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    file_name: str = Field(default="", max_length=255)
    extension: str = Field(default="", max_length=32)
    size_bytes: int = 0
    document_type: str = Field(default="other", max_length=80)
    folder_id: str = Field(default="", max_length=120)
    ocr_text: str = ""
    issuer: str = Field(default="", max_length=180)
    document_number: str = Field(default="", max_length=180)
    extracted_fields: dict[str, str] = Field(default_factory=dict)
    expiry_date: datetime | None = None
    is_favorite: bool = False
    is_verified: bool = False
    client_added_at: datetime | None = None
    client_updated_at: datetime | None = None


class DigiDocumentPatch(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=180)
    document_type: str | None = Field(default=None, max_length=80)
    folder_id: str | None = Field(default=None, max_length=120)
    ocr_text: str | None = None
    issuer: str | None = Field(default=None, max_length=180)
    document_number: str | None = Field(default=None, max_length=180)
    extracted_fields: dict[str, str] | None = None
    expiry_date: datetime | None = None
    is_favorite: bool | None = None
    is_verified: bool | None = None
    client_updated_at: datetime | None = None


class DigiDocumentResponse(ORMModel):
    id: int
    local_id: str
    title: str
    file_name: str
    file_path: str | None
    extension: str
    size_bytes: int
    document_type: str
    folder_id: str
    ocr_text: str
    issuer: str
    document_number: str
    extracted_fields: dict[str, str]
    expiry_date: datetime | None
    is_favorite: bool
    is_verified: bool
    client_added_at: datetime | None
    client_updated_at: datetime | None
    created_at: datetime
    updated_at: datetime
