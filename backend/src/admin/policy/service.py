from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.policy.dtos import PolicyPageCreate, PolicyPageResponse, PolicyPageUpdate
from src.database.models import PolicyPage, PolicyType
from src.shared.dtos import MessageResponse


class PolicyService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_policy(self, payload: PolicyPageCreate) -> PolicyPageResponse:
        policy = PolicyPage(**payload.model_dump(mode="json"))
        self.db.add(policy)
        await self.db.commit()
        await self.db.refresh(policy)
        return PolicyPageResponse.model_validate(policy)

    async def list_policies(
        self,
        *,
        policy_type: PolicyType | None = None,
        active_only: bool = False,
    ) -> list[PolicyPageResponse]:
        query = select(PolicyPage)
        if policy_type is not None:
            query = query.where(PolicyPage.policy_type == policy_type)
        if active_only:
            query = query.where(PolicyPage.is_active.is_(True))
        query = query.order_by(PolicyPage.updated_at.desc(), PolicyPage.id.desc())
        policies = (await self.db.scalars(query)).all()
        return [PolicyPageResponse.model_validate(policy) for policy in policies]

    async def get_policy(self, policy_id: int) -> PolicyPageResponse:
        policy = await self._get_policy(policy_id)
        return PolicyPageResponse.model_validate(policy)

    async def get_latest_policy_by_type(
        self,
        policy_type: PolicyType,
    ) -> PolicyPageResponse | None:
        policy = await self.db.scalar(
            select(PolicyPage)
            .where(
                PolicyPage.policy_type == policy_type,
                PolicyPage.is_active.is_(True),
            )
            .order_by(PolicyPage.updated_at.desc(), PolicyPage.id.desc())
        )
        if not policy:
            return None
        return PolicyPageResponse.model_validate(policy)

    async def update_policy(
        self,
        policy_id: int,
        payload: PolicyPageUpdate,
    ) -> PolicyPageResponse:
        policy = await self._get_policy(policy_id)
        for field, value in payload.model_dump(exclude_unset=True, mode="json").items():
            setattr(policy, field, value)
        await self.db.commit()
        await self.db.refresh(policy)
        return PolicyPageResponse.model_validate(policy)

    async def delete_policy(self, policy_id: int) -> MessageResponse:
        policy = await self._get_policy(policy_id)
        await self.db.delete(policy)
        await self.db.commit()
        return MessageResponse(message="Policy deleted successfully")

    async def _get_policy(self, policy_id: int) -> PolicyPage:
        policy = await self.db.get(PolicyPage, policy_id)
        if not policy:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Policy not found",
            )
        return policy
