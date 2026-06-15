from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.models.post import Post
from app.models.user import User
from app.utils.auth import get_current_user

router = APIRouter(prefix="/api/moments", tags=["moments"])


class PostRequest(BaseModel):
    content: str | None = None
    images: list[str] | None = None  # URL 列表


@router.post("")
def create_post(
    req: PostRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """发布动态"""
    import json
    post = Post(
        user_id=current_user.id,
        content=req.content,
        images=json.dumps(req.images) if req.images else None,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return {
        "id": post.id,
        "content": post.content,
        "images": json.loads(post.images) if post.images else [],
        "created_at": post.created_at.isoformat(),
    }


@router.get("")
def get_moments(
    page: int = 1,
    page_size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """获取动态列表（分页）"""
    import json
    posts = (
        db.query(Post)
        .order_by(Post.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    result = []
    for p in posts:
        user = db.query(User).get(p.user_id)
        result.append({
            "id": p.id,
            "user": {
                "id": user.id,
                "username": user.username,
                "nickname": user.nickname,
                "avatar_url": user.avatar_url,
            },
            "content": p.content,
            "images": json.loads(p.images) if p.images else [],
            "created_at": p.created_at.isoformat(),
        })
    return result
