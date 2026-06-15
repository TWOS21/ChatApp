from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.database import get_db
from app.models.message import Message, MessageType
from app.models.user import User
from app.schemas.message import SendMessageRequest, MessageResponse
from app.utils.auth import get_current_user

router = APIRouter(prefix="/api/messages", tags=["messages"])


@router.post("/send", response_model=MessageResponse)
def send_message(
    req: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """发送一条消息"""
    receiver = db.query(User).get(req.receiver_id)
    if not receiver:
        raise HTTPException(status_code=404, detail="接收者不存在")

    msg = Message(
        sender_id=current_user.id,
        receiver_id=req.receiver_id,
        content=req.content,
        msg_type=req.msg_type,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


@router.get("/conversations")
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """获取当前用户的会话列表"""
    recent = (
        db.query(Message)
        .filter(
            or_(
                Message.sender_id == current_user.id,
                Message.receiver_id == current_user.id,
            )
        )
        .order_by(Message.created_at.desc())
        .limit(100)
        .all()
    )

    user_ids = set()
    for msg in recent:
        other_id = (
            msg.receiver_id
            if msg.sender_id == current_user.id
            else msg.sender_id
        )
        user_ids.add(other_id)

    conversations = []
    for uid in user_ids:
        user = db.query(User).get(uid)
        if not user:
            continue
        last_msg = (
            db.query(Message)
            .filter(
                or_(
                    (Message.sender_id == current_user.id)
                    & (Message.receiver_id == uid),
                    (Message.sender_id == uid)
                    & (Message.receiver_id == current_user.id),
                )
            )
            .order_by(Message.created_at.desc())
            .first()
        )
        conversations.append(
            {
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "nickname": user.nickname,
                    "avatar_url": user.avatar_url,
                },
                "last_message": {
                    "content": last_msg.content if last_msg else None,
                    "msg_type": last_msg.msg_type.value if last_msg else None,
                    "created_at": last_msg.created_at.isoformat() if last_msg else None,
                },
            }
        )

    return conversations


@router.get("/history/{user_id}", response_model=list[MessageResponse])
def get_message_history(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """获取与指定用户的聊天历史"""
    messages = (
        db.query(Message)
        .filter(
            or_(
                (Message.sender_id == current_user.id)
                & (Message.receiver_id == user_id),
                (Message.sender_id == user_id)
                & (Message.receiver_id == current_user.id),
            )
        )
        .order_by(Message.created_at.asc())
        .limit(100)
        .all()
    )
    return messages
