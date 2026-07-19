from datetime import datetime

from pydantic import EmailStr

from src.shared.dtos import ORMModel


class AdminUserResponse(ORMModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime
