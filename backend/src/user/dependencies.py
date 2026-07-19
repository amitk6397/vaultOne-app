from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.settings import settings
from src.database.models import User, UserTokenState
from src.database.session import get_db

user_oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.api_v1_prefix}/user/auth/login"
)


async def get_current_user(
    token: str = Depends(user_oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid user token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as exc:
        raise credentials_error from exc

    if payload.get("role") != "user":
        raise credentials_error

    subject = payload.get("sub")
    if not subject:
        raise credentials_error

    user = await db.get(User, int(subject))
    if not user or not user.is_active:
        raise credentials_error
    token_state = await db.get(UserTokenState, user.id)
    if token_state and int(payload.get("session_version", 0)) != token_state.session_version:
        raise credentials_error
    return user
