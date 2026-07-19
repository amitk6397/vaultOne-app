from datetime import datetime
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.auth.dtos import (
    AdminForgotPasswordRequest,
    AdminLoginRequest,
    AdminResetPasswordRequest,
    OnboardingSlideResponse,
    OnboardingSlideUpdate,
)
from src.config.cloudinary_config import delete_from_cloudinary, public_id_from_url, upload_to_cloudinary
from src.core.email import send_otp_email
from src.core.otp import generate_otp, otp_expiry_time
from src.core.security import create_access_token, create_refresh_token, hash_password, verify_password
from src.database.models import Admin, OnboardingSlide, OtpPurpose, OtpVerification
from src.shared.dtos import MessageResponse, TokenResponse

ALLOWED_IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


class AdminAuthService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def login(self, payload: AdminLoginRequest) -> TokenResponse:
        admin = await self.db.scalar(
            select(Admin).where(Admin.email == payload.email.lower())
        )
        if not admin or not verify_password(payload.password, admin.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
            )
        if not admin.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin account is inactive",
            )
        token = create_access_token(subject=str(admin.id), claims={"role": "admin"})
        return TokenResponse(
            access_token=token,
            refresh_token=create_refresh_token(subject=str(admin.id), claims={"role": "admin"}),
        )

    async def forgot_password(
        self,
        payload: AdminForgotPasswordRequest,
    ) -> MessageResponse:
        admin = await self.db.scalar(
            select(Admin).where(Admin.email == payload.email.lower())
        )
        if admin and admin.is_active:
            otp = generate_otp()
            self.db.add(
                OtpVerification(
                    user_id=None,
                    identity=admin.email,
                    otp_hash=hash_password(otp),
                    purpose=OtpPurpose.forgot_password,
                    expires_at=otp_expiry_time(),
                )
            )
            send_otp_email(
                to_email=admin.email,
                otp=otp,
                purpose="admin_forgot_password",
            )
            await self.db.commit()
        return MessageResponse(message="If the account exists, reset instructions were sent")

    async def reset_password(
        self,
        payload: AdminResetPasswordRequest,
    ) -> MessageResponse:
        if payload.password != payload.confirm_password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Passwords do not match",
            )

        admin = await self.db.scalar(
            select(Admin).where(Admin.email == payload.email.lower())
        )
        if not admin or not admin.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid reset request",
            )

        otp_record = await self.db.scalar(
            select(OtpVerification)
            .where(
                OtpVerification.identity == admin.email,
                OtpVerification.purpose == OtpPurpose.forgot_password,
                OtpVerification.verified_at.is_(None),
            )
            .order_by(OtpVerification.created_at.desc())
        )
        if not otp_record:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
        if otp_record.expires_at < datetime.utcnow():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP expired")
        if not verify_password(payload.otp, otp_record.otp_hash):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")

        otp_record.verified_at = datetime.utcnow()
        admin.password_hash = hash_password(payload.password)
        await self.db.commit()
        return MessageResponse(message="Password reset successfully")

    async def create_onboarding_slide(
        self,
        *,
        title: str,
        subtitle: str,
        image_url: str | None = None,
        image_file: UploadFile | None = None,
        is_active: bool = True,
    ) -> OnboardingSlideResponse:
        image = await self._resolve_onboarding_image(
            image_url=image_url,
            image_file=image_file,
        )
        slide = OnboardingSlide(
            image=image,
            title=title.strip(),
            subtitle=subtitle.strip(),
            is_active=is_active,
        )
        self.db.add(slide)
        await self.db.commit()
        await self.db.refresh(slide)
        return OnboardingSlideResponse.model_validate(slide)

    async def list_onboarding_slides(
        self,
        *,
        active_only: bool = False,
    ) -> list[OnboardingSlideResponse]:
        query = select(OnboardingSlide)
        if active_only:
            query = query.where(OnboardingSlide.is_active.is_(True))
        query = query.order_by(OnboardingSlide.id.asc())
        slides = (await self.db.scalars(query)).all()
        return [OnboardingSlideResponse.model_validate(slide) for slide in slides]

    async def get_onboarding_slide(self, slide_id: int) -> OnboardingSlideResponse:
        slide = await self._get_onboarding_slide(slide_id)
        return OnboardingSlideResponse.model_validate(slide)

    async def update_onboarding_slide(
        self,
        slide_id: int,
        payload: OnboardingSlideUpdate,
        image_file: UploadFile | None = None,
    ) -> OnboardingSlideResponse:
        slide = await self._get_onboarding_slide(slide_id)
        update_data = payload.model_dump(exclude_unset=True, exclude_none=True)
        image_url = update_data.pop("image_url", None)
        if image_url is not None or image_file is not None:
            old_image = slide.image
            slide.image = await self._resolve_onboarding_image(
                image_url=image_url,
                image_file=image_file,
            )
        for field, value in update_data.items():
            setattr(slide, field, value.strip() if isinstance(value, str) else value)
        await self.db.commit()
        await self.db.refresh(slide)
        if "old_image" in locals() and old_image and "res.cloudinary.com" in old_image:
            await delete_from_cloudinary(public_id_from_url(old_image))
        return OnboardingSlideResponse.model_validate(slide)

    async def delete_onboarding_slide(self, slide_id: int) -> MessageResponse:
        slide = await self._get_onboarding_slide(slide_id)
        image = slide.image
        await self.db.delete(slide)
        await self.db.commit()
        if image and "res.cloudinary.com" in image:
            await delete_from_cloudinary(public_id_from_url(image))
        return MessageResponse(message="Onboarding slide deleted successfully")

    async def _get_onboarding_slide(self, slide_id: int) -> OnboardingSlide:
        slide = await self.db.get(OnboardingSlide, slide_id)
        if not slide:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Onboarding slide not found",
            )
        return slide

    async def _resolve_onboarding_image(
        self,
        *,
        image_url: str | None,
        image_file: UploadFile | None,
    ) -> str:
        if image_url and image_file:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Provide either image_url or image_file",
            )
        if image_url:
            return image_url.strip()
        if image_file:
            return await self._save_onboarding_image(image_file)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide image_url or image_file",
        )

    async def _save_onboarding_image(self, image_file: UploadFile) -> str:
        extension = ALLOWED_IMAGE_TYPES.get(image_file.content_type or "")
        if extension is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only JPEG, PNG, and WEBP images are allowed",
            )
        result = await upload_to_cloudinary(
            image_file,
            folder="vaultone/admin/onboarding",
            public_id=uuid4().hex,
            resource_type="image",
        )
        return result["secure_url"]
