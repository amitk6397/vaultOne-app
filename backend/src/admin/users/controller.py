from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.users.service import AdminUserService
from src.shared.dtos import DataResponse


class AdminUserController:
    def __init__(self, db: AsyncSession) -> None:
        self.service = AdminUserService(db)

    async def list_users(self) -> DataResponse:
        users = await self.service.list_users()
        return DataResponse(message="Users fetched successfully", data=users)

    async def block_user(self, user_id: int) -> DataResponse:
        user = await self.service.set_user_active(user_id, is_active=False)
        return DataResponse(message="User blocked successfully", data=user)

    async def unblock_user(self, user_id: int) -> DataResponse:
        user = await self.service.set_user_active(user_id, is_active=True)
        return DataResponse(message="User unblocked successfully", data=user)

    async def delete_user(self, user_id: int) -> DataResponse:
        deleted = await self.service.delete_user(user_id)
        return DataResponse(
            message="User and all associated data deleted permanently",
            data=deleted,
        )
