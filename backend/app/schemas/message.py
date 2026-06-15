import datetime
from pydantic import BaseModel

from app.models.message import MessageType


class SendMessageRequest(BaseModel):
    receiver_id: int
    content: str | None = None
    msg_type: MessageType = MessageType.TEXT


class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    content: str | None
    msg_type: MessageType
    file_url: str | None
    created_at: datetime.datetime

    model_config = {"from_attributes": True}
