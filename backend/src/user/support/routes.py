from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import AppContentPage, SupportMessage, SupportThread, User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user

router = APIRouter(prefix="/user/support", tags=["user-support"])

DEFAULTS = {
    "help": {"title": "Help & Support", "subtitle": "FAQs and direct support", "sections": [
        {"title": "Contact", "body": "Send us a message and our support team will reply here."},
        {"title": "FAQs", "body": "Find help for your account, vault, security and billing."},
    ]},
    "about": {"title": "About VaultOne", "subtitle": "Your secure digital vault", "sections": [
        {"title": "VaultOne", "body": "A secure digital locker for documents, passwords and media."},
        {"title": "Version", "body": "1.0.0"},
    ]},
}

class MessagePayload(BaseModel):
    message: str = Field(min_length=1, max_length=4000)

def page_data(page: AppContentPage | None, key: str) -> dict:
    return DEFAULTS[key] if page is None else {"title": page.title, "subtitle": page.subtitle, "sections": page.sections, "updated_at": page.updated_at}

def message_data(row: SupportMessage) -> dict:
    return {"id": row.id, "thread_id": row.thread_id, "sender_type": row.sender_type, "message": row.message, "is_read": row.is_read, "created_at": row.created_at}

@router.get("/content/{page_key}", response_model=DataResponse)
async def content(page_key: str, db: AsyncSession = Depends(get_db), _: User = Depends(get_current_user)) -> DataResponse:
    if page_key not in DEFAULTS: raise HTTPException(status_code=404, detail="Content page not found")
    page = await db.scalar(select(AppContentPage).where(AppContentPage.page_key == page_key))
    return DataResponse(message="Content fetched", data=page_data(page, page_key))

async def get_thread(db: AsyncSession, user_id: int, create: bool = False) -> SupportThread | None:
    thread = await db.scalar(select(SupportThread).where(SupportThread.user_id == user_id))
    if not thread and create:
        thread = SupportThread(user_id=user_id); db.add(thread); await db.flush()
    return thread

@router.get("/messages", response_model=DataResponse)
async def messages(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    thread = await get_thread(db, user.id)
    if not thread: return DataResponse(message="Messages fetched", data=[])
    rows = (await db.scalars(select(SupportMessage).where(SupportMessage.thread_id == thread.id).order_by(SupportMessage.created_at))).all()
    await db.execute(update(SupportMessage).where(SupportMessage.thread_id == thread.id, SupportMessage.sender_type == "admin").values(is_read=True)); await db.commit()
    return DataResponse(message="Messages fetched", data=[message_data(x) for x in rows])

@router.post("/messages", response_model=DataResponse)
async def send_message(payload: MessagePayload, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> DataResponse:
    thread = await get_thread(db, user.id, create=True)
    row = SupportMessage(thread_id=thread.id, sender_type="user", message=payload.message.strip())
    thread.status, thread.last_message_at = "open", datetime.utcnow(); db.add(row); await db.commit(); await db.refresh(row)
    return DataResponse(message="Message sent", data=message_data(row))
