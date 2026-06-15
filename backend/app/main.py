from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import Base, engine
from app.routers import auth, messages, ws, upload, moments, friends


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时自动建表
    Base.metadata.create_all(bind=engine)
    # 确保存储目录存在
    settings.STORAGE_DIR.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title=settings.APP_NAME,
    lifespan=lifespan,
)

# 允许跨域（Flutter 开发时需要）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router)
app.include_router(messages.router)
app.include_router(ws.router)
app.include_router(upload.router)
app.include_router(moments.router)
app.include_router(friends.router)

# 挂载文件存储目录为静态文件
app.mount("/static", StaticFiles(directory=str(settings.STORAGE_DIR)), name="static")


@app.get("/")
def root():
    return {"message": "ChatApp API is running"}
