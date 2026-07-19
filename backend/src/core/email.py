import smtplib
import json
import logging
from email.message import EmailMessage
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from fastapi import HTTPException, status

from src.config.settings import settings

logger = logging.getLogger(__name__)


def _masked_email(value: str) -> str:
    local, separator, domain = value.strip().partition("@")
    if not separator:
        return "invalid-email"
    visible = local[:2]
    return f"{visible}{'*' * max(1, len(local) - len(visible))}@{domain}"


def send_otp_email(*, to_email: str, otp: str, purpose: str) -> None:
    subject = "VaultOne OTP Verification"
    body = (
        f"Your VaultOne OTP is {otp}.\n\n"
        f"Purpose: {purpose.replace('_', ' ')}\n"
        f"This OTP expires in {settings.otp_expire_minutes} minutes."
    )

    if settings.brevo_api_key and settings.brevo_from_email:
        _send_with_brevo(to_email=to_email, subject=subject, body=body)
        return

    if not settings.smtp_host or not settings.smtp_username or not settings.smtp_password:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Email OTP service is not configured",
        )

    from_email = settings.smtp_from_email or settings.smtp_username
    message = EmailMessage()
    message["From"] = f"{settings.smtp_from_name} <{from_email}>"
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            if settings.smtp_use_tls:
                smtp.starttls()
            smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)
        logger.info("SMTP accepted OTP email recipient=%s", _masked_email(to_email))
    except (smtplib.SMTPException, OSError) as error:
        logger.exception("SMTP rejected OTP email recipient=%s", _masked_email(to_email))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="OTP email provider rejected the request",
        ) from error


def _send_with_brevo(*, to_email: str, subject: str, body: str) -> None:
    payload = {
        "sender": {"email": settings.brevo_from_email, "name": settings.brevo_from_name},
        "to": [{"email": to_email}],
        "subject": subject,
        "textContent": body,
    }
    request = Request(
        "https://api.brevo.com/v3/smtp/email",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "api-key": settings.brevo_api_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=15) as response:
            if response.status not in {200, 201, 202}:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Brevo did not accept the OTP email",
                )
            response_body = json.loads(response.read().decode("utf-8") or "{}")
            message_id = response_body.get("messageId", "not-provided")
            logger.info(
                "Brevo accepted OTP email recipient=%s message_id=%s",
                _masked_email(to_email),
                message_id,
            )
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="ignore")
        logger.error(
            "Brevo rejected OTP email recipient=%s status=%s",
            _masked_email(to_email),
            error.code,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Brevo OTP email failed: {detail or error.reason}",
        ) from error
    except URLError as error:
        logger.error(
            "Brevo OTP request failed recipient=%s reason=%s",
            _masked_email(to_email),
            error.reason,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Brevo OTP email failed: {error.reason}",
        ) from error
