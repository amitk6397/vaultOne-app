from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.admin.policy.controller import AdminPolicyController
from src.admin.policy.dtos import PolicyPageCreate, PolicyPageUpdate
from src.database.models import Admin, PolicyType
from src.database.session import get_db
from src.shared.dtos import DataResponse

router = APIRouter(prefix="/admin/policies", tags=["admin-policy"])


def get_controller(db: AsyncSession = Depends(get_db)) -> AdminPolicyController:
    return AdminPolicyController(db)


@router.post("", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def create_policy(
    payload: PolicyPageCreate,
    controller: AdminPolicyController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.create_policy(payload)


@router.get("", response_model=DataResponse)
async def list_policies(
    policy_type: PolicyType | None = Query(default=None),
    controller: AdminPolicyController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.list_policies(policy_type)


@router.get("/{policy_id}", response_model=DataResponse)
async def get_policy(
    policy_id: int,
    controller: AdminPolicyController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.get_policy(policy_id)


@router.put("/{policy_id}", response_model=DataResponse)
async def update_policy(
    policy_id: int,
    payload: PolicyPageUpdate,
    controller: AdminPolicyController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.update_policy(policy_id, payload)


@router.delete("/{policy_id}", response_model=DataResponse)
async def delete_policy(
    policy_id: int,
    controller: AdminPolicyController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.delete_policy(policy_id)
