from fastapi import WebSocket


class ConnectionManager:
    """管理所有 WebSocket 连接，支持点对点消息"""

    def __init__(self):
        # user_id -> list[WebSocket]（一个用户可能多设备登录）
        self.active_connections: dict[int, list[WebSocket]] = {}

    async def connect(self, user_id: int, ws: WebSocket):
        await ws.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(ws)

    def disconnect(self, user_id: int, ws: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].remove(ws)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_to_user(self, user_id: int, message: dict):
        """给指定用户推送消息"""
        if user_id in self.active_connections:
            for ws in self.active_connections[user_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    self.disconnect(user_id, ws)


manager = ConnectionManager()
