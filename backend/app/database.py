from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

# SQLite 需要 check_same_thread=False，PostgreSQL 不需要
connect_args = {}
if not settings.IS_POSTGRES:
    connect_args["check_same_thread"] = False

engine = create_engine(settings.DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


# 依赖注入：每个请求拿到自己的数据库会话
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
