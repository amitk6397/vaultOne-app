import asyncio
from datetime import datetime, timedelta
from pathlib import Path

import cloudinary.uploader
import cloudinary.utils

from src.config.cloudinary_config import delete_from_cloudinary
from src.config.settings import settings

CLOUD_PREFIX = "cloudinary:"
LOCAL_PREFIX = "local:"


def is_cloud_key(storage_key: str) -> bool:
    return storage_key.startswith(CLOUD_PREFIX)


def local_relative_key(storage_key: str) -> str:
    return storage_key.removeprefix(LOCAL_PREFIX)


async def finalize_private_upload(path: Path, storage_key: str) -> str:
    if settings.vault_connect_storage_backend.lower() == "local":
        return f"{LOCAL_PREFIX}{storage_key}"
    public_id = f"vaultone/connect/{storage_key}"
    result = await asyncio.to_thread(
        cloudinary.uploader.upload,
        str(path),
        public_id=public_id,
        resource_type="raw",
        type="authenticated",
        use_filename=False,
        unique_filename=False,
        overwrite=False,
    )
    return f"{CLOUD_PREFIX}{result['public_id']}"


def signed_private_download_url(storage_key: str, file_name: str) -> str:
    if not is_cloud_key(storage_key):
        raise ValueError("Signed cloud URL requested for a local attachment")
    stored_public_id = storage_key.removeprefix(CLOUD_PREFIX)
    # Cloudinary's private download API requires the asset format separately.
    # Raw uploads keep the extension in public_id, so passing an empty format
    # signs a different request and Cloudinary rejects it with HTTP 401.
    suffix = Path(stored_public_id).suffix
    if not suffix:
        raise ValueError("Cloud attachment is missing its file format")
    public_id = stored_public_id[: -len(suffix)]
    return cloudinary.utils.private_download_url(
        public_id,
        suffix.lstrip(".").lower(),
        resource_type="raw",
        type="authenticated",
        attachment=file_name,
        expires_at=int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
    )


async def delete_private_object(storage_key: str, storage_root: Path) -> None:
    if is_cloud_key(storage_key):
        await delete_from_cloudinary(
            storage_key.removeprefix(CLOUD_PREFIX),
            resource_type="raw",
            delivery_type="authenticated",
        )
        return
    path = storage_root / local_relative_key(storage_key)
    if path.is_file():
        path.unlink()
