from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.admin.users.controller import AdminUserController
from src.database.models import Admin
from src.database.session import get_db
from src.shared.dtos import DataResponse

router = APIRouter(prefix="/admin/users", tags=["admin-users"])


def get_controller(db: AsyncSession = Depends(get_db)) -> AdminUserController:
    return AdminUserController(db)


@router.get("", response_model=DataResponse)
async def list_users(
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.list_users()


@router.patch("/{user_id}/block", response_model=DataResponse)
async def block_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.block_user(user_id)


@router.patch("/{user_id}/unblock", response_model=DataResponse)
async def unblock_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.unblock_user(user_id)


@router.delete("/{user_id}", response_model=DataResponse)
async def delete_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.delete_user(user_id)
