from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.email import send_otp_email
from src.config.settings import settings
from src.core.otp import generate_otp, otp_expiry_time
from src.core.security import create_access_token, create_refresh_token, hash_password, verify_password
from src.database.models import (
    OnboardingSlide, OtpPurpose, OtpVerification, User,
    UserAuthEvent, UserAuthEventType, UserTokenState,
)
from src.shared.dtos import MessageResponse, TokenResponse
from src.user.auth.dtos import (
    ForgotPasswordRequest,
    LoginRequest,
    LoginOtpRequest,
    OnboardingSlideResponse,
    RegisterResponse,
    RegisterRequest,
    ResetPasswordRequest,
    ResendOtpRequest,
    UserAuthResponse,
    UserResponse,
    VerifyOtpRequest,
)


class UserAuthService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def register(self, payload: RegisterRequest) -> RegisterResponse:
        existing = await self.db.scalar(
            select(User).where(or_(User.email == payload.email, User.phone == payload.phone))
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email or phone number already exists",
            )

        user = User(
            full_name=payload.full_name.strip(),
            email=payload.email.lower(),
            phone=payload.phone,
            password_hash=hash_password(payload.password),
        )
        self.db.add(user)
        await self.db.flush()
        self.db.add(UserAuthEvent(
            user_id=user.id,
            event_type=UserAuthEventType.register,
            auth_method="password",
        ))
        otp = await self._create_otp(user.id, user.email, OtpPurpose.register, user.email)
        await self.db.commit()
        await self.db.refresh(user)
        return RegisterResponse(
            user=UserResponse.model_validate(user),
            otp=otp if settings.is_development else None,
        )

    async def login(self, payload: LoginRequest) -> UserAuthResponse:
        user = await self._find_user_by_identity(payload.identity)
        if not user or not verify_password(payload.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive",
            )
        if not user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Verify your email OTP before logging in",
            )
        self.db.add(UserAuthEvent(
            user_id=user.id,
            event_type=UserAuthEventType.login,
            auth_method="password",
        ))
        await self.db.commit()
        return await self._auth_response(user, remember_me=payload.remember_me)

    async def send_login_otp(self, payload: LoginOtpRequest) -> MessageResponse:
        user = await self._find_user_by_identity(payload.email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Account not found",
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive",
            )
        if not user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Verify your registration OTP before logging in",
            )
        otp = await self._create_otp(user.id, user.email, OtpPurpose.login, user.email)
        await self.db.commit()
        return MessageResponse(
            message="OTP sent successfully",
            otp=otp if settings.is_development else None,
        )

    async def forgot_password(self, payload: ForgotPasswordRequest) -> MessageResponse:
        user = await self._find_user_by_identity(payload.identity)
        if user:
            otp = await self._create_otp(
                user.id,
                user.email,
                OtpPurpose.forgot_password,
                user.email,
            )
            await self.db.commit()
            return MessageResponse(
                message="If the account exists, reset instructions were sent",
                otp=otp if settings.is_development else None,
            )
        return MessageResponse(message="If the account exists, reset instructions were sent")

    async def verify_otp(self, payload: VerifyOtpRequest) -> UserAuthResponse | MessageResponse:
        otp_identity = await self._otp_identity(payload.identity)
        otp_record = await self.db.scalar(
            select(OtpVerification)
            .where(
                OtpVerification.identity == otp_identity,
                OtpVerification.purpose == payload.purpose,
                OtpVerification.verified_at.is_(None),
            )
            .order_by(OtpVerification.created_at.desc())
        )
        if not otp_record:
            raise HTTPException(status_code=400, detail="Invalid OTP")
        if otp_record.expires_at < datetime.utcnow():
            raise HTTPException(status_code=400, detail="OTP expired")
        if not verify_password(payload.otp, otp_record.otp_hash):
            raise HTTPException(status_code=400, detail="Invalid OTP")

        otp_record.verified_at = datetime.utcnow()
        user = await self.db.get(User, otp_record.user_id) if otp_record.user_id else None
        if payload.purpose == OtpPurpose.register and otp_record.user_id:
            if user:
                user.is_verified = True
        if payload.purpose == OtpPurpose.login and user:
            if not user.is_verified:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Verify your registration OTP before logging in",
                )
            self.db.add(UserAuthEvent(
                user_id=user.id,
                event_type=UserAuthEventType.login,
                auth_method="otp",
            ))
        await self.db.commit()
        if payload.purpose in {OtpPurpose.register, OtpPurpose.login}:
            if not user:
                raise HTTPException(status_code=400, detail="User not found")
            return await self._auth_response(user)
        return MessageResponse(message="OTP verified successfully")

    async def reset_password(self, payload: ResetPasswordRequest) -> MessageResponse:
        user = await self._find_user_by_identity(payload.identity)
        if not user:
            raise HTTPException(status_code=400, detail="Invalid reset request")
        otp_record = await self.db.scalar(
            select(OtpVerification)
            .where(
                OtpVerification.user_id == user.id,
                OtpVerification.identity == user.email,
                OtpVerification.purpose == OtpPurpose.forgot_password,
            )
            .order_by(OtpVerification.created_at.desc())
        )
        if (
            not otp_record
            or otp_record.expires_at < datetime.utcnow()
            or not verify_password(payload.otp, otp_record.otp_hash)
        ):
            raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        user.password_hash = hash_password(payload.password)
        await self.db.delete(otp_record)
        await self.db.commit()
        return MessageResponse(message="Password reset successfully")

    async def resend_otp(self, payload: ResendOtpRequest) -> MessageResponse:
        user = await self._find_user_by_identity(payload.identity)
        otp_identity = user.email if user else self._normalize_identity(payload.identity)
        otp = await self._create_otp(
            user.id if user else None,
            otp_identity,
            payload.purpose,
            otp_identity,
        )
        await self.db.commit()
        return MessageResponse(
            message="OTP sent successfully",
            otp=otp if settings.is_development else None,
        )

    async def list_onboarding_slides(self) -> list[OnboardingSlideResponse]:
        slides = (
            await self.db.scalars(
                select(OnboardingSlide)
                .where(OnboardingSlide.is_active.is_(True))
                .order_by(OnboardingSlide.id.asc())
            )
        ).all()
        return [OnboardingSlideResponse.model_validate(slide) for slide in slides]

    async def _find_user_by_identity(self, identity: str) -> User | None:
        clean_identity = self._normalize_identity(identity)
        return await self.db.scalar(
            select(User).where(or_(User.email == clean_identity, User.phone == clean_identity))
        )

    async def _auth_response(
        self,
        user: User,
        *,
        remember_me: bool = False,
    ) -> UserAuthResponse:
        token_state = await self.db.get(UserTokenState, user.id)
        session_version = token_state.session_version if token_state else 0
        token = create_access_token(
            subject=str(user.id),
            claims={
                "role": "user",
                "remember_me": remember_me,
                "session_version": session_version,
            },
        )
        return UserAuthResponse(
            access_token=token,
            refresh_token=create_refresh_token(
                subject=str(user.id),
                claims={"role": "user", "session_version": session_version},
            ),
            user=UserResponse.model_validate(user),
        )

    async def _otp_identity(self, identity: str) -> str:
        user = await self._find_user_by_identity(identity)
        if user:
            return user.email
        return self._normalize_identity(identity)

    async def _create_otp(
        self,
        user_id: int | None,
        identity: str,
        purpose: OtpPurpose,
        to_email: str,
    ) -> str:
        otp = generate_otp()
        self.db.add(
            OtpVerification(
                user_id=user_id,
                identity=self._normalize_identity(identity),
                otp_hash=hash_password(otp),
                purpose=purpose,
                expires_at=otp_expiry_time(),
            )
        )
        send_otp_email(to_email=to_email, otp=otp, purpose=purpose.value)
        return otp

    @staticmethod
    def _normalize_identity(identity: str) -> str:
        trimmed = identity.strip().lower()
        if "@" in trimmed:
            return trimmed
        return "".join(char for char in trimmed if char.isdigit())
