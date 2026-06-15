from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    # 应用配置
    APP_NAME: str = "ChatApp"
    DEBUG: bool = True

    # 数据库 — 先用 SQLite 零配置启动，后面想换 PostgreSQL 只改这一行
    DATABASE_URL: str = "sqlite:///./chatapp.db"

    # JWT 认证
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 天

    # 文件存储路径
    STORAGE_DIR: Path = Path(__file__).parent.parent / "storage"
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB

    class Config:
        env_file = ".env"


settings = Settings()
