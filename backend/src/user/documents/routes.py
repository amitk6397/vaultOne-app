import json

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.models import User, UserDigiDocument
from sqlalchemy import select
from src.database.session import get_db
from src.shared.dtos import DataResponse
from src.user.dependencies import get_current_user
from src.user.documents.controller import UserDigiDocumentController
from src.user.documents.dtos import DigiDocumentPatch, DigiDocumentUpsert
from src.user.subscriptions.quota import ensure_storage_quota

router = APIRouter(prefix="/user/documents", tags=["user-documents"])


def get_controller(
    db: AsyncSession = Depends(get_db),
) -> UserDigiDocumentController:
    return UserDigiDocumentController(db)


@router.get("", response_model=DataResponse)
async def list_documents(
    controller: UserDigiDocumentController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.list_documents(current_user)


@router.put("/{local_id}", response_model=DataResponse)
async def upsert_document(
    local_id: str,
    payload: DigiDocumentUpsert,
    controller: UserDigiDocumentController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.upsert_document(local_id, payload, current_user)


@router.post("", response_model=DataResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    local_id: str = Form(...),
    metadata: str = Form(...),
    controller: UserDigiDocumentController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DataResponse:
    try:
        payload = DigiDocumentUpsert.model_validate(json.loads(metadata))
    except (json.JSONDecodeError, ValidationError) as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document metadata",
        ) from error
    existing = await db.scalar(select(UserDigiDocument).where(UserDigiDocument.user_id == current_user.id, UserDigiDocument.local_id == local_id))
    await ensure_storage_quota(db, current_user.id, file.size or 0, existing.size_bytes if existing else 0)
    return await controller.upload_document(
        local_id=local_id,
        payload=payload,
        file=file,
        current_user=current_user,
    )


@router.patch("/{local_id}", response_model=DataResponse)
async def patch_document(
    local_id: str,
    payload: DigiDocumentPatch,
    controller: UserDigiDocumentController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.patch_document(local_id, payload, current_user)


@router.delete("/{local_id}", response_model=DataResponse)
async def delete_document(
    local_id: str,
    controller: UserDigiDocumentController = Depends(get_controller),
    current_user: User = Depends(get_current_user),
) -> DataResponse:
    return await controller.delete_document(local_id, current_user)
