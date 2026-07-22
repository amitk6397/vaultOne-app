import asyncio
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import Any

import socketio
from fastapi.encoders import jsonable_encoder

from src.core.notifications import send_event_push
from src.core.security import decode_token
from src.database.models import User, UserTokenState
from src.database.session import AsyncSessionLocal
from src.user.connect.dtos import SendMessageRequest
from src.user.connect.service import (
    check_access, config, is_blocked, mark_receipt, message_data,
    other_participant, require_member, send_message,
)


sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")


class ConnectionManager:
    def __init__(self) -> None:
        self.connections: dict[int, set[str]] = defaultdict(set)
        self.users: dict[str, int] = {}
        self.joined: dict[str, set[str]] = defaultdict(set)
        self.message_hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: int, sid: str) -> None:
        async with self._lock:
            self.connections[user_id].add(sid)
            self.users[sid] = user_id
        await sio.enter_room(sid, f"user:{user_id}")

    async def disconnect(self, sid: str) -> tuple[int | None, set[str]]:
        async with self._lock:
            user_id = self.users.pop(sid, None)
            conversations = self.joined.pop(sid, set())
            self.message_hits.pop(sid, None)
            if user_id is not None:
                self.connections[user_id].discard(sid)
                if not self.connections[user_id]:
                    self.connections.pop(user_id, None)
            return user_id, conversations

    async def disconnect_user(self, user_id: int) -> None:
        for sid in tuple(self.connections.get(user_id, ())):
            await sio.disconnect(sid)

    def online(self, user_id: int) -> bool:
        return bool(self.connections.get(user_id))

    async def emit_user(self, user_id: int, event: str, data: dict[str, Any]) -> None:
        # Socket.IO uses stdlib json rather than FastAPI's response encoder.
        # Convert datetimes/enums before emitting so a successful DB write is
        # never turned into an HTTP 500 by realtime delivery.
        await sio.emit(event, jsonable_encoder(data), room=f"user:{user_id}")

    async def emit_conversation(self, conversation_id: str, user_ids: list[int], event: str, data: dict, exclude: int | None = None) -> None:
        for user_id in user_ids:
            if user_id != exclude:
                await self.emit_user(user_id, event, data)

    async def emit_summaries(self, db, conversation_id: str, user_ids: list[int]) -> None:
        from src.user.connect.service import conversation_data
        from src.user.connect.models import Conversation
        conversation = await db.get(Conversation, conversation_id)
        if conversation:
            for user_id in user_ids:
                await self.emit_user(
                    user_id, "conversation.updated",
                    await conversation_data(db, conversation, user_id),
                )


manager = ConnectionManager()


async def _authenticate(token: str | None) -> tuple[int, int]:
    if not token:
        raise ValueError("Missing token")
    claims = decode_token(token)
    if claims.get("role") != "user" or claims.get("token_type") != "access":
        raise ValueError("Invalid token")
    return int(claims["sub"]), int(claims.get("session_version", 0))


async def _validate_session(db, user_id: int, token_version: int) -> User:
    user = await db.get(User, user_id)
    token_state = await db.get(UserTokenState, user_id)
    expected_version = token_state.session_version if token_state else 0
    if not user or not user.is_active or token_version != expected_version:
        raise ValueError("Session revoked")
    await check_access(db, user_id)
    return user


async def _session(sid: str) -> tuple[int, int]:
    session = await sio.get_session(sid)
    return int(session["user_id"]), int(session["token_version"])


@sio.event
async def connect(sid, environ, auth):
    token = (auth or {}).get("token")
    if not token:
        token = environ.get("QUERY_STRING", "").removeprefix("token=")
    try:
        user_id, token_version = await _authenticate(token)
        async with AsyncSessionLocal() as db:
            await _validate_session(db, user_id, token_version)
    except Exception:
        return False
    await sio.save_session(sid, {"user_id": user_id, "token_version": token_version})
    await manager.connect(user_id, sid)
    await sio.emit("socket.ready", {
        "user_id": user_id,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }, room=sid)


@sio.event
async def disconnect(sid, reason=None):
    user_id, conversations = await manager.disconnect(sid)
    if user_id is None or manager.online(user_id):
        return
    async with AsyncSessionLocal() as db:
        for conversation_id in conversations:
            try:
                other_id = await other_participant(db, conversation_id, user_id)
                if not await is_blocked(db, user_id, other_id):
                    await manager.emit_user(other_id, "user.offline", {
                        "conversation_id": conversation_id, "user_id": user_id,
                    })
            except Exception:
                pass


@sio.on("conversation.join")
async def conversation_join(sid, data):
    user_id, token_version = await _session(sid)
    conversation_id = str((data or {}).get("conversation_id", ""))
    async with AsyncSessionLocal() as db:
        await _validate_session(db, user_id, token_version)
        await require_member(db, conversation_id, user_id)
        manager.joined[sid].add(conversation_id)
        await sio.enter_room(sid, f"conversation:{conversation_id}")
        other_id = await other_participant(db, conversation_id, user_id)
        if not await is_blocked(db, user_id, other_id):
            await manager.emit_user(user_id, "user.online" if manager.online(other_id) else "user.offline", {"conversation_id": conversation_id, "user_id": other_id})
            await manager.emit_user(other_id, "user.online", {"conversation_id": conversation_id, "user_id": user_id})


@sio.on("conversation.leave")
async def conversation_leave(sid, data):
    conversation_id = str((data or {}).get("conversation_id", ""))
    manager.joined[sid].discard(conversation_id)
    await sio.leave_room(sid, f"conversation:{conversation_id}")


@sio.on("message.send")
async def message_send(sid, data):
    user_id, token_version = await _session(sid)
    async with AsyncSessionLocal() as db:
        await _validate_session(db, user_id, token_version)
        hits = manager.message_hits[sid]
        now = datetime.now(timezone.utc).timestamp()
        cfg = await config(db)
        while hits and hits[0] <= now - 60:
            hits.popleft()
        if len(hits) >= cfg.message_rate_limit:
            raise ValueError("Message rate limit exceeded")
        hits.append(now)
        payload = SendMessageRequest.model_validate(data or {})
        message, recipients = await send_message(db, user_id, payload)
        serialized = await message_data(db, message, user_id)
        users = [user_id, *recipients]
        await manager.emit_conversation(message.conversation_id, users, "message.created", serialized)
        await manager.emit_summaries(db, message.conversation_id, users)
        for recipient in recipients:
            from src.user.connect.service import unread_message_count
            if (
                not manager.online(recipient)
                and await unread_message_count(db, message.conversation_id, recipient) == 1
            ):
                await send_event_push(db, title="VaultOne", body="You received a secure message", user_id=recipient, event_type="vault_connect_message", data={"type": "VAULT_CONNECT_MESSAGE", "conversationId": message.conversation_id, "messageId": message.id})
    return serialized


async def _receipt(sid: str, data: dict, read: bool):
    user_id, token_version = await _session(sid)
    message_id = str((data or {}).get("message_id", ""))
    async with AsyncSessionLocal() as db:
        await _validate_session(db, user_id, token_version)
        receipt = await mark_receipt(db, message_id, user_id, read)
        from src.user.connect.models import Message
        message = await db.get(Message, message_id)
        event = "message.read" if read else "message.delivered"
        payload = {"message_id": message_id, "user_id": user_id, "delivered_at": receipt.delivered_at.isoformat() if receipt.delivered_at else None, "read_at": receipt.read_at.isoformat() if receipt.read_at else None}
        await manager.emit_user(message.sender_user_id, event, payload)
        await manager.emit_summaries(db, message.conversation_id, [user_id, message.sender_user_id])
        return payload


@sio.on("message.delivered")
async def message_delivered(sid, data):
    return await _receipt(sid, data, False)


@sio.on("message.read")
async def message_read(sid, data):
    return await _receipt(sid, data, True)


async def _typing(sid: str, data: dict, active: bool):
    user_id, token_version = await _session(sid)
    conversation_id = str((data or {}).get("conversation_id", ""))
    async with AsyncSessionLocal() as db:
        await _validate_session(db, user_id, token_version)
        await require_member(db, conversation_id, user_id)
        other_id = await other_participant(db, conversation_id, user_id)
        if not await is_blocked(db, user_id, other_id):
            await manager.emit_user(other_id, "typing.started" if active else "typing.stopped", {"conversation_id": conversation_id, "user_id": user_id})


@sio.on("typing.start")
async def typing_start(sid, data):
    await _typing(sid, data, True)


@sio.on("typing.stop")
async def typing_stop(sid, data):
    await _typing(sid, data, False)
