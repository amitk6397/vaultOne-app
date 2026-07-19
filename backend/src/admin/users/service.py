from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.users.dtos import AdminUserResponse
from src.database.models import User


class AdminUserService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_users(self) -> list[AdminUserResponse]:
        users = (
            await self.db.scalars(
                select(User).order_by(User.created_at.desc(), User.id.desc())
            )
        ).all()
        return [AdminUserResponse.model_validate(user) for user in users]

    async def set_user_active(
        self,
        user_id: int,
        *,
        is_active: bool,
    ) -> AdminUserResponse:
        user = await self.db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        user.is_active = is_active
        await self.db.commit()
        await self.db.refresh(user)
        return AdminUserResponse.model_validate(user)
