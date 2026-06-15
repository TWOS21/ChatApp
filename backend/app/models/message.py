import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey, func, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.database import Base


class MessageType(str, enum.Enum):
    TEXT = "text"
    IMAGE = "image"
    VOICE = "voice"
    VIDEO = "video"
    SYSTEM = "system"


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    sender_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    receiver_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    content: Mapped[str | None] = mapped_column(String(2000), default=None)
    msg_type: Mapped[MessageType] = mapped_column(
        SAEnum(MessageType), default=MessageType.TEXT
    )
    file_url: Mapped[str | None] = mapped_column(String(500), default=None)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, server_default=func.now()
    )

    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])
