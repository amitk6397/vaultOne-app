from src.database.models import User
from src.shared.dtos import DataResponse
from src.user.ai.dtos import AiChatRequest, AiChatResponse, AiOcrRequest, AiOcrResponse
from src.user.ai.service import UserAiService


class UserAiController:
    def __init__(self) -> None:
        self.service = UserAiService()

    async def chat(self, payload: AiChatRequest, current_user: User) -> DataResponse:
        result = await self.service.chat(
            payload.message.strip(),
            user_name=current_user.full_name,
            app_context=payload.app_context,
        )
        return DataResponse(
            message="AI response generated successfully",
            data=AiChatResponse(**result).model_dump(),
        )

    async def ocr(self, payload: AiOcrRequest) -> DataResponse:
        result = await self.service.extract_image(
            payload.image_base64, payload.mime_type, payload.target
        )
        return DataResponse(
            message="Image extracted successfully",
            data=AiOcrResponse(**result).model_dump(),
        )
