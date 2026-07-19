from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.policy.service import PolicyService
from src.database.models import PolicyType
from src.shared.dtos import DataResponse


class UserPolicyController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = PolicyService(db)

    async def get_privacy_policy(self) -> DataResponse:
        return await self.get_policy_by_type(PolicyType.privacy)

    async def get_terms_and_conditions(self) -> DataResponse:
        return await self.get_policy_by_type(PolicyType.terms_and_conditions)

    async def get_policy_by_type(self, policy_type: PolicyType) -> DataResponse:
        policy = await self.service.get_latest_policy_by_type(policy_type)
        return DataResponse(message="Policy fetched successfully", data=policy)
