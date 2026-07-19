from fastapi import APIRouter, Depends

from src.database.models import User
from src.shared.dtos import DataResponse
from src.user.ai.controller import UserAiController
from src.user.ai.dtos import AiChatRequest, AiOcrRequest
from src.user.dependencies import get_current_user

router = APIRouter(prefix="/user/ai", tags=["user-ai"])


def get_controller() -> UserAiController:
    return UserAiController()


@router.post("/chat", response_model=DataResponse)
async def chat(
    payload: AiChatRequest,
    controller: UserAiController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.chat(payload, current_user)


@router.post("/ocr", response_model=DataResponse)
async def ocr(
    payload: AiOcrRequest,
    controller: UserAiController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.ocr(payload)
