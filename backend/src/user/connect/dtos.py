from typing import Literal
from pydantic import BaseModel, Field, field_validator

DISAPPEARING_OPTIONS = {0, 3600, 86400, 604800, 2592000}
REPORT_CATEGORIES = {"spam", "harassment", "abusive_content", "fraud_or_scam", "illegal_content", "privacy_violation", "other"}


class ContactDiscoverRequest(BaseModel):
    phones: list[str] = Field(min_length=1, max_length=500)
    @field_validator("phones")
    @classmethod
    def valid_phones(cls, values: list[str]) -> list[str]:
        normalized = []
        for value in values:
            phone = value.strip().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
            if not phone.startswith("+") or not phone[1:].isdigit() or not 8 <= len(phone[1:]) <= 15:
                raise ValueError("All phone numbers must use E.164 format")
            normalized.append(phone)
        return list(dict.fromkeys(normalized))


class DirectConversationRequest(BaseModel):
    user_id: int = Field(gt=0)


class DisappearingMessagesRequest(BaseModel):
    duration_seconds: int = 0
    @field_validator("duration_seconds")
    @classmethod
    def supported(cls, value: int) -> int:
        if value not in DISAPPEARING_OPTIONS:
            raise ValueError("Unsupported disappearing-message duration")
        return value


class SendMessageRequest(BaseModel):
    client_message_id: str = Field(min_length=8, max_length=80)
    conversation_id: str
    message_type: Literal["text", "image", "video", "document", "voice"] = "text"
    content: str | None = Field(default=None, max_length=10000)
    reply_to_message_id: str | None = None
    attachment_ids: list[str] = Field(default_factory=list, max_length=10)


class DeleteMessageRequest(BaseModel):
    scope: Literal["me", "everyone"] = "me"


class InitUploadRequest(BaseModel):
    conversation_id: str
    file_name: str = Field(min_length=1, max_length=255)
    mime_type: str = Field(min_length=3, max_length=160)
    file_size: int = Field(gt=0)
    file_type: Literal["image", "video", "document", "voice"]
    checksum: str | None = Field(default=None, pattern=r"^[a-fA-F0-9]{64}$")


class CompleteUploadRequest(BaseModel):
    checksum: str = Field(pattern=r"^[a-fA-F0-9]{64}$")


class ReportRequest(BaseModel):
    reported_user_id: int = Field(gt=0)
    conversation_id: str | None = None
    message_id: str | None = None
    attachment_id: str | None = None
    category: str
    description: str = Field(default="", max_length=4000)
    @field_validator("category")
    @classmethod
    def supported_category(cls, value: str) -> str:
        if value not in REPORT_CATEGORIES:
            raise ValueError("Unsupported report category")
        return value
