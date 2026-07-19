import secrets
from datetime import datetime, timedelta

from src.config.settings import settings


def generate_otp() -> str:
    start = 10 ** (settings.otp_length - 1)
    end = (10**settings.otp_length) - 1
    return str(secrets.randbelow(end - start + 1) + start)


def otp_expiry_time() -> datetime:
    return datetime.utcnow() + timedelta(minutes=settings.otp_expire_minutes)
