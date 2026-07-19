from typing import Any

from pydantic import BaseModel, Field


class AiChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    app_context: dict[str, Any] | None = None


class AiChatResponse(BaseModel):
    reply: str
    model: str


class AiOcrRequest(BaseModel):
    image_base64: str = Field(min_length=1)
    mime_type: str = Field(pattern=r"^(image/(jpeg|png|webp)|application/pdf)$")
    target: str = Field(default="document", pattern=r"^(document|secure_note|password)$")


class AiOcrResponse(BaseModel):
    raw_text: str
    title: str
    document_type: str = "Other"
    fields: dict[str, str] = Field(default_factory=dict)
    model: str
