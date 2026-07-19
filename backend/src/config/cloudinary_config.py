import asyncio
from pathlib import PurePosixPath
from typing import Any

import cloudinary
import cloudinary.uploader
from cloudinary.exceptions import AuthorizationRequired, Error as CloudinaryError
from fastapi import HTTPException, UploadFile, status

from src.config.settings import settings


_cloudinary_config = cloudinary.config()
if (
    settings.cloudinary_cloud_name
    and settings.cloudinary_api_key
    and settings.cloudinary_api_secret
):
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )
elif settings.cloudinary_url:
    try:
        _cloudinary_config._load_from_url(settings.cloudinary_url)
    except (AttributeError, ValueError) as error:
        raise ValueError(
            "CLOUDINARY_URL must use cloudinary://api_key:api_secret@cloud_name"
        ) from error
    cloudinary.config(secure=True)
else:
    raise ValueError(
        "Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and "
        "CLOUDINARY_API_SECRET"
    )


async def upload_to_cloudinary(
    file: UploadFile,
    *,
    folder: str,
    public_id: str,
    resource_type: str = "auto",
) -> dict[str, Any]:
    await file.seek(0)
    try:
        return await asyncio.to_thread(
            cloudinary.uploader.upload,
            file.file,
            folder=folder,
            public_id=public_id,
            resource_type=resource_type,
            use_filename=False,
            unique_filename=False,
            overwrite=False,
        )
    except AuthorizationRequired as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Cloudinary credentials are invalid. Check Cloudinary environment variables.",
        ) from error
    except CloudinaryError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Cloudinary upload is temporarily unavailable.",
        ) from error


async def delete_from_cloudinary(
    public_id: str,
    *,
    resource_type: str = "image",
    delivery_type: str = "upload",
) -> None:
    await asyncio.to_thread(
        cloudinary.uploader.destroy,
        public_id,
        resource_type=resource_type,
        type=delivery_type,
        invalidate=True,
    )


def public_id_from_url(url: str, *, keep_suffix: bool = False) -> str:
    upload_path = url.split("/upload/", 1)[1]
    parts = upload_path.split("/")
    if parts and parts[0].startswith("v") and parts[0][1:].isdigit():
        parts = parts[1:]
    path = PurePosixPath("/".join(parts))
    return str(path if keep_suffix else path.with_suffix(""))
