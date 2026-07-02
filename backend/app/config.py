from pydantic_settings import BaseSettings
from pathlib import Path
from urllib.parse import urlparse


class Settings(BaseSettings):
    # 应用配置
    APP_NAME: str = "ChatApp"
    DEBUG: bool = True

    # 数据库 — 默认 SQLite；部署时设 DATABASE_URL 环境变量自动切 PostgreSQL
    DATABASE_URL: str = "sqlite:///./chatapp.db"

    # JWT 认证 — 生产环境务必通过环境变量覆盖
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 天

    # 文件存储路径
    STORAGE_DIR: Path = Path(__file__).parent.parent / "storage"
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB

    @property
    def IS_POSTGRES(self) -> bool:
        return self.DATABASE_URL.startswith("postgresql")

    class Config:
        env_file = ".env"


settings = Settings()
