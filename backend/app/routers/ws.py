from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.message import Message
from app.models.user import User
from app.utils.security import decode_access_token
from app.utils.ws_manager import manager

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket, token: str = Query(...)):
    """WebSocket 连接，需传入 token 认证"""
    # 验证 token
    payload = decode_access_token(token)
    if not payload:
        await ws.close(code=4001, reason="无效的令牌")
        return

    user_id = int(payload["sub"])

    # 获取数据库会话
    db = SessionLocal()
    user = db.query(User).get(user_id)
    if not user:
        await ws.close(code=4001, reason="用户不存在")
        db.close()
        return
    db.close()

    # 注册连接
    await manager.connect(user_id, ws)
    print(f"[WS] 用户 {user.username}({user_id}) 已连接")

    try:
        while True:
            data = await ws.receive_json()

            msg_type = data.get("type", "text")
            content = data.get("content", "")
            receiver_id = data.get("receiver_id")

            if not receiver_id:
                continue

            # 存到数据库
            db = SessionLocal()
            msg = Message(
                sender_id=user_id,
                receiver_id=receiver_id,
                content=content,
                msg_type=msg_type,
            )
            db.add(msg)
            db.commit()
            db.refresh(msg)
            db.close()

            # 拼装推送消息
            payload = {
                "id": msg.id,
                "sender_id": user_id,
                "receiver_id": receiver_id,
                "content": content,
                "msg_type": msg_type,
                "sender_name": user.username,
                "created_at": msg.created_at.isoformat(),
            }

            # 推给接收者
            await manager.send_to_user(receiver_id, payload)

            # 如果接收者不是自己，也推给自己（让发送方也能实时收到回显）
            if receiver_id != user_id:
                await manager.send_to_user(user_id, payload)

    except WebSocketDisconnect:
        manager.disconnect(user_id, ws)
        print(f"[WS] 用户 {user.username}({user_id}) 已断开")
    except Exception as e:
        manager.disconnect(user_id, ws)
        print(f"[WS] 连接异常: {e}")
