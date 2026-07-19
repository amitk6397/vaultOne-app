from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import PolicyType
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.policy.controller import UserPolicyController

router = APIRouter(prefix="/user/policies", tags=["user-policy"])


def get_controller(db: AsyncSession = Depends(get_db)) -> UserPolicyController:
    return UserPolicyController(db)


@router.get("/privacy", response_model=DataResponse)
async def get_privacy_policy(
    controller: UserPolicyController = Depends(get_controller),
) -> DataResponse:
    return await controller.get_privacy_policy()


@router.get("/terms-and-conditions", response_model=DataResponse)
async def get_terms_and_conditions(
    controller: UserPolicyController = Depends(get_controller),
) -> DataResponse:
    return await controller.get_terms_and_conditions()


@router.get("/{policy_type}", response_model=DataResponse)
async def get_policy_by_type(
    policy_type: PolicyType,
    controller: UserPolicyController = Depends(get_controller),
) -> DataResponse:
    return await controller.get_policy_by_type(policy_type)
