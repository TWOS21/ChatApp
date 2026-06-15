from pydantic import BaseModel

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.database import get_db
from app.models.user import User
from app.models.friendship import Friendship, FriendStatus
from app.utils.auth import get_current_user

router = APIRouter(prefix="/api/friends", tags=["friends"])


class FriendRequest(BaseModel):
    friend_id: int


class RespondRequest(BaseModel):
    request_id: int
    accept: bool


@router.get("/search")
def search_users(
    q: str = Query(min_length=1),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """搜索用户（按用户名或昵称）"""
    users = (
        db.query(User)
        .filter(
            User.id != current_user.id,
            or_(User.username.ilike(f"%{q}%"), User.nickname.ilike(f"%{q}%")),
        )
        .limit(20)
        .all()
    )
    return [
        {
            "id": u.id,
            "username": u.username,
            "nickname": u.nickname,
            "avatar_url": u.avatar_url,
            "bio": u.bio,
        }
        for u in users
    ]


@router.post("/request")
def send_friend_request(
    req: FriendRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """发送好友请求"""
    friend_id = req.friend_id
    if friend_id == current_user.id:
        raise HTTPException(status_code=400, detail="不能添加自己为好友")

    target = db.query(User).get(friend_id)
    if not target:
        raise HTTPException(status_code=404, detail="用户不存在")

    existing = (
        db.query(Friendship)
        .filter(
            or_(
                (Friendship.user_id == current_user.id)
                & (Friendship.friend_id == friend_id),
                (Friendship.user_id == friend_id)
                & (Friendship.friend_id == current_user.id),
            )
        )
        .first()
    )
    if existing:
        if existing.status == FriendStatus.ACCEPTED:
            raise HTTPException(status_code=400, detail="已经是好友了")
        if existing.status == FriendStatus.PENDING:
            raise HTTPException(status_code=400, detail="已发送过好友请求")

    friend_request = Friendship(
        user_id=current_user.id,
        friend_id=friend_id,
        status=FriendStatus.PENDING,
    )
    db.add(friend_request)
    db.commit()
    return {"message": "好友请求已发送", "friendship_id": friend_request.id}


@router.post("/respond")
def respond_friend_request(
    req: RespondRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """同意/拒绝好友请求"""
    request_id = req.request_id
    accept = req.accept
    friendship = db.query(Friendship).get(request_id)
    if not friendship:
        raise HTTPException(status_code=404, detail="请求不存在")
    if friendship.friend_id != current_user.id:
        raise HTTPException(status_code=403, detail="无权操作此请求")
    if friendship.status != FriendStatus.PENDING:
        raise HTTPException(status_code=400, detail="请求已处理")

    friendship.status = FriendStatus.ACCEPTED if accept else FriendStatus.REJECTED
    db.commit()
    status_text = "已同意" if accept else "已拒绝"
    return {"message": f"好友请求{status_text}"}


@router.get("/")
def list_friends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """好友列表"""
    friendships = (
        db.query(Friendship)
        .filter(
            or_(
                (Friendship.user_id == current_user.id)
                | (Friendship.friend_id == current_user.id),
            ),
            Friendship.status == FriendStatus.ACCEPTED,
        )
        .all()
    )
    result = []
    for f in friendships:
        friend_id = f.friend_id if f.user_id == current_user.id else f.user_id
        friend = db.query(User).get(friend_id)
        if friend:
            result.append(
                {
                    "friendship_id": f.id,
                    "user": {
                        "id": friend.id,
                        "username": friend.username,
                        "nickname": friend.nickname,
                        "avatar_url": friend.avatar_url,
                        "bio": friend.bio,
                    },
                    "created_at": f.created_at.isoformat() if f.created_at else None,
                }
            )
    return result


@router.get("/requests")
def list_friend_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """收到的好友请求列表（待处理）"""
    requests = (
        db.query(Friendship)
        .filter(
            Friendship.friend_id == current_user.id,
            Friendship.status == FriendStatus.PENDING,
        )
        .all()
    )
    result = []
    for r in requests:
        requester = db.query(User).get(r.user_id)
        if requester:
            result.append(
                {
                    "id": r.id,
                    "user": {
                        "id": requester.id,
                        "username": requester.username,
                        "nickname": requester.nickname,
                        "avatar_url": requester.avatar_url,
                    },
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
            )
    return result


@router.get("/status/{user_id}")
def check_friend_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """查看与某用户的好友状态"""
    friendship = (
        db.query(Friendship)
        .filter(
            or_(
                (Friendship.user_id == current_user.id)
                & (Friendship.friend_id == user_id),
                (Friendship.user_id == user_id)
                & (Friendship.friend_id == current_user.id),
            ),
        )
        .first()
    )
    if not friendship:
        return {"status": "none"}
    return {"status": friendship.status.value, "friendship_id": friendship.id}
