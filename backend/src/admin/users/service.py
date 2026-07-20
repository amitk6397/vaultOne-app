from fastapi import HTTPException, status
from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.users.dtos import AdminUserResponse
from src.database.models import (
    OtpVerification,
    PaymentAuditLog,
    SubscriptionPayment,
    User,
    UserAuthEvent,
    UserSubscription,
)
from src.user.connect.models import Conversation, ConversationMember, MessageAttachment
from src.user.connect.routes import STORAGE_ROOT
from src.user.connect.storage import delete_private_object
from src.user.profile.controller import UserProfileController


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

    async def delete_user(self, user_id: int) -> dict[str, int]:
        user = await self.db.get(User, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        # Delete user-owned Cloudinary objects before their database rows.
        profile = UserProfileController(self.db)
        for section in ("files", "documents", "photos", "videos", "passwords"):
            await profile.delete_data_section(section, user)

        conversation_ids = list((await self.db.scalars(
            select(ConversationMember.conversation_id).where(
                ConversationMember.user_id == user_id
            )
        )).all())
        attachment_query = select(MessageAttachment).where(
            MessageAttachment.owner_user_id == user_id
        )
        if conversation_ids:
            attachment_query = select(MessageAttachment).where(
                MessageAttachment.conversation_id.in_(conversation_ids)
            )
        attachments = (await self.db.scalars(attachment_query)).all()
        for attachment in attachments:
            try:
                await delete_private_object(attachment.storage_key, STORAGE_ROOT)
            except Exception as error:
                print(f"User deletion attachment cleanup deferred: {error}")

        if conversation_ids:
            await self.db.execute(
                update(Conversation)
                .where(Conversation.id.in_(conversation_ids))
                .values(last_message_id=None)
            )
            await self.db.execute(
                delete(Conversation).where(Conversation.id.in_(conversation_ids))
            )

        payment_ids = list((await self.db.scalars(
            select(SubscriptionPayment.id).where(
                SubscriptionPayment.user_id == user_id
            )
        )).all())
        if payment_ids:
            await self.db.execute(
                delete(UserSubscription).where(
                    UserSubscription.payment_id.in_(payment_ids)
                )
            )
            await self.db.execute(
                delete(PaymentAuditLog).where(
                    PaymentAuditLog.payment_id.in_(payment_ids)
                )
            )
            await self.db.execute(
                delete(SubscriptionPayment).where(
                    SubscriptionPayment.id.in_(payment_ids)
                )
            )
        await self.db.execute(
            delete(UserSubscription).where(UserSubscription.user_id == user_id)
        )
        await self.db.execute(
            delete(OtpVerification).where(OtpVerification.user_id == user_id)
        )
        await self.db.execute(
            delete(UserAuthEvent).where(UserAuthEvent.user_id == user_id)
        )
        await self.db.delete(user)
        await self.db.commit()
        return {
            "user_id": user_id,
            "conversations_deleted": len(conversation_ids),
            "attachments_deleted": len(attachments),
            "payments_deleted": len(payment_ids),
        }
