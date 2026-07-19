from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.policy.dtos import PolicyPageCreate, PolicyPageUpdate
from src.admin.policy.service import PolicyService
from src.database.models import PolicyType
from src.shared.dtos import DataResponse


class AdminPolicyController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = PolicyService(db)

    async def create_policy(self, payload: PolicyPageCreate) -> DataResponse:
        policy = await self.service.create_policy(payload)
        return DataResponse(message="Policy created successfully", data=policy)

    async def list_policies(self, policy_type: PolicyType | None) -> DataResponse:
        policies = await self.service.list_policies(policy_type=policy_type)
        return DataResponse(message="Policies fetched successfully", data=policies)

    async def get_policy(self, policy_id: int) -> DataResponse:
        policy = await self.service.get_policy(policy_id)
        return DataResponse(message="Policy fetched successfully", data=policy)

    async def update_policy(
        self,
        policy_id: int,
        payload: PolicyPageUpdate,
    ) -> DataResponse:
        policy = await self.service.update_policy(policy_id, payload)
        return DataResponse(message="Policy updated successfully", data=policy)

    async def delete_policy(self, policy_id: int) -> DataResponse:
        response = await self.service.delete_policy(policy_id)
        return DataResponse(message=response.message, data=None)
