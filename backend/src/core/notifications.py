import asyncio
import logging
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import App, credentials, messaging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.settings import settings
from src.database.models import (
    PushNotificationLog,
    User,
    UserDeviceToken,
    UserNotification,
)

logger = logging.getLogger(__name__)


def firebase_credentials_path() -> Path:
    path = Path(settings.firebase_credentials_path).expanduser()
    if not path.is_absolute():
        path = Path(__file__).resolve().parents[2] / path
    return path.resolve()


def initialize_firebase() -> App:
    """Return the process-wide Firebase app, initializing it when necessary."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        path = firebase_credentials_path()
        if not path.is_file():
            raise RuntimeError(
                "Firebase service-account credentials were not found at "
                f"{path}. Set FIREBASE_CREDENTIALS_PATH in backend/.env."
            )
        try:
            app = firebase_admin.initialize_app(
                credentials.Certificate(str(path)),
            )
        except (OSError, ValueError) as error:
            raise RuntimeError(
                "Firebase service-account credentials are invalid"
            ) from error
        logger.info("Firebase Admin initialized project=%s", app.project_id)
        return app


def _is_unregistered_token(error: Exception) -> bool:
    value = str(error).lower()
    return (
        isinstance(error, messaging.UnregisteredError)
        or "registration-token-not-registered" in value
        or "requested entity was not found" in value
    )


async def send_push(
    db: AsyncSession,
    *,
    title: str,
    body: str,
    user_id: int | None = None,
    data: dict[str, Any] | None = None,
    admin_id: int | None = None,
    event_type: str = "manual",
) -> dict[str, int]:
    query = select(UserDeviceToken).where(UserDeviceToken.is_active.is_(True))
    if user_id is not None:
        query = query.where(UserDeviceToken.user_id == user_id)
    devices = list((await db.scalars(query)).all())
    payload = {
        str(key): str(value)
        for key, value in (data or {}).items()
        if value is not None
    }

    if user_id is None:
        recipient_ids = list(
            (
                await db.scalars(
                    select(User.id).where(User.is_active.is_(True))
                )
            ).all()
        )
    else:
        recipient_ids = [user_id]

    db.add_all(
        [
            UserNotification(
                user_id=recipient_id,
                title=title,
                body=body,
                data=payload,
                event_type=event_type,
            )
            for recipient_id in recipient_ids
        ]
    )
    # Persist the inbox notification before attempting external delivery.
    await db.commit()

    success_count = 0
    failure_count = 0
    if devices:
        try:
            app = initialize_firebase()
            for start in range(0, len(devices), 500):
                batch = devices[start : start + 500]
                message = messaging.MulticastMessage(
                    notification=messaging.Notification(title=title, body=body),
                    data=payload,
                    tokens=[device.token for device in batch],
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(
                            channel_id="vaultone_notifications",
                            sound="default",
                        ),
                    ),
                    apns=messaging.APNSConfig(
                        payload=messaging.APNSPayload(
                            aps=messaging.Aps(sound="default", badge=1)
                        )
                    ),
                )
                response = await asyncio.to_thread(
                    messaging.send_each_for_multicast,
                    message,
                    app=app,
                )
                success_count += response.success_count
                failure_count += response.failure_count
                for device, result in zip(batch, response.responses):
                    if (
                        not result.success
                        and result.exception
                        and _is_unregistered_token(result.exception)
                    ):
                        device.is_active = False
        except Exception:
            failure_count = len(devices) - success_count
            logger.exception(
                "FCM delivery failed; inbox notifications were retained"
            )

    log = PushNotificationLog(
        title=title,
        body=body,
        target_type="user" if user_id is not None else "all",
        target_user_id=user_id,
        data=payload,
        success_count=success_count,
        failure_count=failure_count,
        created_by_admin_id=admin_id,
        event_type=event_type,
    )
    db.add(log)
    await db.commit()
    return {
        "notification_id": log.id,
        "targeted_devices": len(devices),
        "success_count": success_count,
        "failure_count": failure_count,
    }


async def send_event_push(db: AsyncSession, **kwargs: Any) -> None:
    """Send a best-effort event notification without failing its business action."""
    try:
        await send_push(db, **kwargs)
    except Exception:
        await db.rollback()
        logger.exception("Push notification event failed")
