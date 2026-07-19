from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from src.admin.dependencies import get_current_admin
from src.database.models import Admin, AppContentPage, SupportMessage, SupportThread, User
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.support.routes import DEFAULTS, message_data, page_data
from src.core.notifications import send_event_push

router = APIRouter(prefix="/admin/support", tags=["admin-support"])

class ContentPayload(BaseModel):
    title: str = Field(min_length=2, max_length=160); subtitle: str = Field(default="", max_length=1000)
    sections: list[dict[str, str]] = Field(default_factory=list)
class ReplyPayload(BaseModel): message: str = Field(min_length=1, max_length=4000)

@router.get("/content/{page_key}", response_model=DataResponse)
async def get_content(page_key: str, db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    if page_key not in DEFAULTS: raise HTTPException(status_code=404, detail="Content page not found")
    page = await db.scalar(select(AppContentPage).where(AppContentPage.page_key == page_key))
    return DataResponse(message="Content fetched", data=page_data(page, page_key))

@router.put("/content/{page_key}", response_model=DataResponse)
async def save_content(page_key: str, payload: ContentPayload, db: AsyncSession = Depends(get_db), admin: Admin = Depends(get_current_admin)) -> DataResponse:
    if page_key not in DEFAULTS: raise HTTPException(status_code=404, detail="Content page not found")
    page = await db.scalar(select(AppContentPage).where(AppContentPage.page_key == page_key))
    if not page: page = AppContentPage(page_key=page_key, title=payload.title); db.add(page)
    page.title, page.subtitle, page.sections, page.updated_by_admin_id = payload.title, payload.subtitle, payload.sections, admin.id
    await db.commit(); await db.refresh(page); return DataResponse(message="Content saved", data=page_data(page, page_key))

@router.get("/threads", response_model=DataResponse)
async def threads(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)) -> DataResponse:
    rows = (await db.scalars(select(SupportThread).order_by(SupportThread.last_message_at.desc()))).all(); data=[]
    for row in rows:
        user=await db.get(User,row.user_id); unread=await db.scalar(select(SupportMessage.id).where(SupportMessage.thread_id==row.id, SupportMessage.sender_type=="user", SupportMessage.is_read.is_(False)).limit(1))
        data.append({"id":row.id,"user_id":row.user_id,"user_name":user.full_name,"user_email":user.email,"status":row.status,"has_unread":bool(unread),"last_message_at":row.last_message_at})
    return DataResponse(message="Threads fetched", data=data)

@router.get("/threads/{thread_id}/messages", response_model=DataResponse)
async def thread_messages(thread_id:int, db:AsyncSession=Depends(get_db), _:Admin=Depends(get_current_admin))->DataResponse:
    thread=await db.get(SupportThread,thread_id)
    if not thread: raise HTTPException(status_code=404,detail="Thread not found")
    rows=(await db.scalars(select(SupportMessage).where(SupportMessage.thread_id==thread_id).order_by(SupportMessage.created_at))).all()
    await db.execute(update(SupportMessage).where(SupportMessage.thread_id==thread_id,SupportMessage.sender_type=="user").values(is_read=True)); await db.commit()
    return DataResponse(message="Messages fetched",data=[message_data(x) for x in rows])

@router.post("/threads/{thread_id}/reply",response_model=DataResponse)
async def reply(thread_id:int,payload:ReplyPayload,db:AsyncSession=Depends(get_db),admin:Admin=Depends(get_current_admin))->DataResponse:
    thread=await db.get(SupportThread,thread_id)
    if not thread: raise HTTPException(status_code=404,detail="Thread not found")
    row=SupportMessage(thread_id=thread_id,sender_type="admin",sender_admin_id=admin.id,message=payload.message.strip()); thread.last_message_at=datetime.utcnow(); db.add(row); await db.commit(); await db.refresh(row)
    await send_event_push(db, title="Support replied", body=payload.message.strip()[:180], user_id=thread.user_id, event_type="support_reply", data={"route":"/profile/support"})
    return DataResponse(message="Reply sent",data=message_data(row))
