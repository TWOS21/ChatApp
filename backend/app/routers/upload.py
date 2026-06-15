import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File

from app.config import settings
from app.models.user import User
from app.utils.auth import get_current_user

router = APIRouter(prefix="/api/upload", tags=["upload"])

ALLOWED_IMAGE = {"image/jpeg", "image/png", "image/gif", "image/webp"}
ALLOWED_VOICE = {"audio/mpeg", "audio/ogg", "audio/wav", "audio/mp4"}
ALLOWED_VIDEO = {"video/mp4", "video/webm", "video/quicktime"}


def _get_subdir(content_type: str) -> str:
    if content_type in ALLOWED_IMAGE:
        return "images"
    elif content_type in ALLOWED_VOICE:
        return "voices"
    elif content_type in ALLOWED_VIDEO:
        return "videos"
    return "others"


@router.post("")
def upload_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    if not file.content_type:
        raise HTTPException(status_code=400, detail="无法识别文件类型")

    subdir = _get_subdir(file.content_type)
    ext = Path(file.filename).suffix if file.filename else ".bin"
    unique_name = f"{uuid.uuid4().hex}{ext}"
    save_path = settings.STORAGE_DIR / subdir / unique_name

    content = file.file.read()
    if len(content) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="文件超过大小限制")
    save_path.write_bytes(content)

    url = f"/static/{subdir}/{unique_name}"
    return {"url": url, "filename": file.filename, "size": len(content)}
