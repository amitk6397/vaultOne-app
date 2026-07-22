from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.admin.dependencies import get_current_admin
from src.admin.users.controller import AdminUserController
from src.database.models import (
    AccountDeletionRequest, AccountDeletionStatus, Admin,
)
from src.database.session import get_db
from src.shared.dtos import DataResponse

router = APIRouter(prefix="/admin/users", tags=["admin-users"])


class DeletionReviewRequest(BaseModel):
    decision: str = Field(pattern="^(approve|reject)$")
    note: str = Field(default="", max_length=1000)


def deletion_request_data(item: AccountDeletionRequest) -> dict:
    return {
        "id": item.id, "user_id": item.user_id,
        "user_name": item.user_name, "user_email": item.user_email,
        "reason_code": item.reason_code, "reason_text": item.reason_text,
        "status": item.status.value, "admin_note": item.admin_note,
        "reviewed_at": item.reviewed_at, "created_at": item.created_at,
    }


def get_controller(db: AsyncSession = Depends(get_db)) -> AdminUserController:
    return AdminUserController(db)


@router.get("", response_model=DataResponse)
async def list_users(
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.list_users()


@router.get("/deletion-requests", response_model=DataResponse)
async def list_deletion_requests(
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    rows = (await db.scalars(select(AccountDeletionRequest).order_by(
        AccountDeletionRequest.created_at.desc()
    ))).all()
    return DataResponse(
        message="Account deletion requests fetched",
        data=[deletion_request_data(item) for item in rows],
    )


@router.patch("/deletion-requests/{request_id}", response_model=DataResponse)
async def review_deletion_request(
    request_id: int,
    payload: DeletionReviewRequest,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    item = await db.get(AccountDeletionRequest, request_id)
    if not item:
        raise HTTPException(404, "Deletion request not found")
    if item.status != AccountDeletionStatus.pending:
        raise HTTPException(409, "Deletion request is already reviewed")
    if payload.decision == "reject" and len(payload.note.strip()) < 3:
        raise HTTPException(422, "A rejection reason is required")
    user_id = item.user_id
    item.status = (
        AccountDeletionStatus.approved
        if payload.decision == "approve"
        else AccountDeletionStatus.rejected
    )
    item.admin_note = payload.note.strip() or None
    item.reviewed_at = datetime.utcnow()
    await db.commit()
    if payload.decision == "approve" and user_id is not None:
        await AdminUserController(db).delete_user(user_id)
    return DataResponse(
        message="Account deletion approved" if payload.decision == "approve" else "Account deletion rejected",
        data={"id": request_id, "status": item.status.value},
    )


@router.patch("/{user_id}/block", response_model=DataResponse)
async def block_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.block_user(user_id)


@router.patch("/{user_id}/unblock", response_model=DataResponse)
async def unblock_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.unblock_user(user_id)


@router.delete("/{user_id}", response_model=DataResponse)
async def delete_user(
    user_id: int,
    controller: AdminUserController = Depends(get_controller),
    _: Admin = Depends(get_current_admin),
) -> DataResponse:
    return await controller.delete_user(user_id)
