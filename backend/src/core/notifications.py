import asyncio
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config.settings import settings
from src.database.models import PushNotificationLog, User, UserDeviceToken, UserNotification


def _firebase_app():
    try:
        return firebase_admin.get_app()
    except ValueError:
        path = Path(settings.firebase_credentials_path)
        if not path.is_absolute():
            path = Path(__file__).resolve().parents[2] / path
        if not path.is_file():
            raise RuntimeError(f"Firebase credentials not found: {path}")
        return firebase_admin.initialize_app(credentials.Certificate(str(path)))


async def send_push(
    db: AsyncSession,
    *,
    title: str,
    body: str,
    user_id: int | None = None,
    data: dict | None = None,
    admin_id: int | None = None,
    event_type: str = "manual",
) -> dict:
    query = select(UserDeviceToken).where(UserDeviceToken.is_active.is_(True))
    if user_id is not None:
        query = query.where(UserDeviceToken.user_id == user_id)
    devices = (await db.scalars(query)).all()
    payload = {str(key): str(value) for key, value in (data or {}).items() if value is not None}
    success_count = failure_count = 0

    if user_id is None:
        recipient_ids = (await db.scalars(select(User.id).where(User.is_active.is_(True)))).all()
    else:
        recipient_ids = [user_id]
    db.add_all([
        UserNotification(
            user_id=recipient_id, title=title, body=body, data=payload,
            event_type=event_type,
        )
        for recipient_id in recipient_ids
    ])
    # Make the inbox item visible before FCM reaches a foreground app, whose
    # provider immediately refreshes the notification list.
    await db.commit()

    if devices:
        try:
            app = _firebase_app()
            for start in range(0, len(devices), 500):
                batch = devices[start : start + 500]
                message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data=payload,
                tokens=[device.token for device in batch],
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="vaultone_notifications", sound="default"
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default", badge=1)
                    )
                ),
            )
                response = await asyncio.to_thread(messaging.send_each_for_multicast, message, app=app)
                success_count += response.success_count
                failure_count += response.failure_count
                for device, result in zip(batch, response.responses):
                    if not result.success and result.exception and (
                        "registration-token-not-registered" in str(result.exception).lower()
                        or "requested entity was not found" in str(result.exception).lower()
                    ):
                        device.is_active = False
        except Exception as error:
            failure_count = len(devices) - success_count
            print(f"FCM delivery failed; inbox notification was retained: {error}")

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


async def send_event_push(db: AsyncSession, **kwargs) -> None:
    """Best-effort event notification; the business operation must stay successful."""
    try:
        await send_push(db, **kwargs)
    except Exception as error:
        await db.rollback()
        print(f"Push notification failed: {error}")
