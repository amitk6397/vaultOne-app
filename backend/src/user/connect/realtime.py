import asyncio
from collections import defaultdict, deque
from datetime import datetime
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from src.core.notifications import send_event_push
from src.core.security import decode_token
from src.database.models import User, UserTokenState
from src.database.session import AsyncSessionLocal
from src.user.connect.dtos import SendMessageRequest
from src.user.connect.service import (
    check_access, config, is_blocked, mark_receipt, message_data, other_participant,
    require_member, send_message,
)

router = APIRouter()


class ConnectionManager:
    def __init__(self) -> None:
        self.connections: dict[int, set[WebSocket]] = defaultdict(set)
        self.joined: dict[WebSocket, set[str]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: int, socket: WebSocket) -> None:
        await socket.accept()
        async with self._lock:
            self.connections[user_id].add(socket)

    async def disconnect(self, user_id: int, socket: WebSocket) -> None:
        async with self._lock:
            self.connections[user_id].discard(socket)
            if not self.connections[user_id]:
                self.connections.pop(user_id, None)
            self.joined.pop(socket, None)

    async def disconnect_user(self, user_id: int) -> None:
        for socket in tuple(self.connections.get(user_id, ())):
            try:
                await socket.close(code=4403, reason="Session revoked")
            except Exception:
                pass
            await self.disconnect(user_id, socket)

    def online(self, user_id: int) -> bool:
        return bool(self.connections.get(user_id))

    async def emit_user(self, user_id: int, event: str, data: dict[str, Any]) -> None:
        dead = []
        for socket in tuple(self.connections.get(user_id, ())):
            try:
                await socket.send_json({"event": event, "data": data})
            except Exception:
                dead.append(socket)
        for socket in dead:
            await self.disconnect(user_id, socket)

    async def emit_conversation(self, conversation_id: str, user_ids: list[int], event: str, data: dict, exclude: int | None = None) -> None:
        for user_id in user_ids:
            if user_id != exclude:
                await self.emit_user(user_id, event, data)


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


@router.websocket("/ws/vault-connect")
async def vault_connect_socket(socket: WebSocket) -> None:
    try:
        user_id, token_version = await _authenticate(socket.query_params.get("token"))
        async with AsyncSessionLocal() as db:
            await _validate_session(db, user_id, token_version)
    except Exception:
        await socket.close(code=4401)
        return

    await manager.connect(user_id, socket)
    message_hits = deque()
    await socket.send_json({"event": "socket.ready", "data": {"user_id": user_id, "server_time": datetime.utcnow().isoformat()}})
    try:
        while True:
            packet = await socket.receive_json()
            event = str(packet.get("event", ""))
            data = packet.get("data") or {}
            async with AsyncSessionLocal() as db:
                await _validate_session(db, user_id, token_version)
                if event == "conversation.join":
                    conversation_id = str(data.get("conversation_id", ""))
                    await require_member(db, conversation_id, user_id)
                    manager.joined[socket].add(conversation_id)
                    other_id = await other_participant(db, conversation_id, user_id)
                    if not await is_blocked(db, user_id, other_id):
                        await manager.emit_user(user_id, "user.online" if manager.online(other_id) else "user.offline", {"conversation_id": conversation_id, "user_id": other_id})
                        await manager.emit_user(other_id, "user.online", {"conversation_id": conversation_id, "user_id": user_id})
                elif event == "conversation.leave":
                    manager.joined[socket].discard(str(data.get("conversation_id", "")))
                elif event == "message.send":
                    now = datetime.utcnow().timestamp()
                    cfg = await config(db)
                    while message_hits and message_hits[0] <= now - 60:
                        message_hits.popleft()
                    if len(message_hits) >= cfg.message_rate_limit:
                        raise ValueError("Message rate limit exceeded")
                    message_hits.append(now)
                    payload = SendMessageRequest.model_validate(data)
                    message, recipients = await send_message(db, user_id, payload)
                    serialized = await message_data(db, message, user_id)
                    await manager.emit_conversation(message.conversation_id, [user_id, *recipients], "message.created", serialized)
                    for recipient in recipients:
                        if not manager.online(recipient):
                            await send_event_push(
                                db, title="VaultOne", body="You received a secure message",
                                user_id=recipient, event_type="vault_connect_message",
                                data={"type": "VAULT_CONNECT_MESSAGE", "conversationId": message.conversation_id, "messageId": message.id},
                            )
                elif event in {"message.delivered", "message.read"}:
                    message_id = str(data.get("message_id", ""))
                    receipt = await mark_receipt(db, message_id, user_id, event.endswith("read"))
                    message = await db.get(__import__("src.user.connect.models", fromlist=["Message"]).Message, message_id)
                    event_name = "message.read" if event.endswith("read") else "message.delivered"
                    await manager.emit_user(message.sender_user_id, event_name, {
                        "message_id": message_id, "user_id": user_id,
                        "delivered_at": receipt.delivered_at.isoformat() if receipt.delivered_at else None,
                        "read_at": receipt.read_at.isoformat() if receipt.read_at else None,
                    })
                elif event in {"typing.start", "typing.stop"}:
                    conversation_id = str(data.get("conversation_id", ""))
                    await require_member(db, conversation_id, user_id)
                    other_id = await other_participant(db, conversation_id, user_id)
                    if not await is_blocked(db, user_id, other_id):
                        await manager.emit_user(other_id, "typing.started" if event.endswith("start") else "typing.stopped", {"conversation_id": conversation_id, "user_id": user_id})
                else:
                    await socket.send_json({"event": "error", "data": {"code": "unsupported_event", "message": "Unsupported event"}})
    except WebSocketDisconnect:
        pass
    except Exception as error:
        try:
            await socket.send_json({"event": "error", "data": {"code": "event_rejected", "message": str(error)}})
        except Exception:
            pass
    finally:
        conversations = set(manager.joined.get(socket, set()))
        await manager.disconnect(user_id, socket)
        if not manager.online(user_id):
            async with AsyncSessionLocal() as db:
                for conversation_id in conversations:
                    try:
                        other_id = await other_participant(db, conversation_id, user_id)
                        if not await is_blocked(db, user_id, other_id):
                            await manager.emit_user(other_id, "user.offline", {"conversation_id": conversation_id, "user_id": user_id})
                    except Exception:
                        pass
