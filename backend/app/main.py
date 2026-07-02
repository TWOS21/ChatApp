from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
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
    # 初始化演示数据（无则插入）
    _run_seed()
    yield


def _run_seed():
    """运行 seed.py 初始化演示数据"""
    import sys
    import os

    seed_path = Path(__file__).parent.parent / "seed.py"
    if not seed_path.exists():
        return

    # 用 subprocess 执行以隔离环境，不影响当前进程
    import subprocess
    result = subprocess.run(
        [sys.executable, str(seed_path)],
        capture_output=True, text=True, cwd=str(seed_path.parent),
    )
    if result.stdout:
        for line in result.stdout.strip().split("\n"):
            print(f"[seed] {line}")
    if result.returncode != 0 and result.stderr:
        print(f"[seed] error: {result.stderr}")
    else:
        print("[seed] done")


app = FastAPI(
    title=settings.APP_NAME,
    lifespan=lifespan,
)

# 允许跨域
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


@app.get("/", response_class=HTMLResponse)
def root():
    return LANDING_PAGE


LANDING_PAGE = """\
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ChatApp — 即时通讯云平台</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background: #0f0f23; color: #e0e0e0; line-height: 1.6; min-height: 100vh;
  }
  .container { max-width: 1000px; margin: 0 auto; padding: 0 24px; }

  /* Header */
  header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 80px 0 60px; text-align: center; position: relative; overflow: hidden;
  }
  header::after {
    content: ''; position: absolute; bottom: 0; left: 0; right: 0;
    height: 40px; background: #0f0f23; border-radius: 50% 50% 0 0 / 100% 100% 0 0;
  }
  header h1 { font-size: 3rem; font-weight: 800; letter-spacing: -1px; margin-bottom: 12px; }
  header h1 span { color: #fbbf24; }
  header p { font-size: 1.2rem; opacity: 0.9; max-width: 600px; margin: 0 auto 24px; }
  .badge {
    display: inline-block; background: rgba(255,255,255,0.15); backdrop-filter: blur(4px);
    padding: 6px 16px; border-radius: 20px; font-size: 0.85rem; margin: 0 4px 8px;
  }

  /* Sections */
  section { padding: 48px 0; }
  section:nth-child(even) { background: #151538; }
  h2 {
    font-size: 1.6rem; font-weight: 700; margin-bottom: 28px;
    display: flex; align-items: center; gap: 10px;
  }
  h2::before { content: ''; display: inline-block; width: 4px; height: 24px; background: #667eea; border-radius: 2px; }

  /* Feature grid */
  .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; }
  .card {
    background: #1a1a3e; border: 1px solid #2a2a5e; border-radius: 12px;
    padding: 24px; transition: transform 0.2s, box-shadow 0.2s;
  }
  .card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(102,126,234,0.15); }
  .card .icon { font-size: 1.8rem; margin-bottom: 10px; }
  .card h3 { font-size: 1.1rem; margin-bottom: 8px; }
  .card p { font-size: 0.9rem; color: #a0a0c0; }

  /* Tech stack */
  .tech-list { display: flex; flex-wrap: wrap; gap: 12px; }
  .tech {
    background: #1a1a3e; border: 1px solid #2a2a5e; border-radius: 8px;
    padding: 10px 18px; font-size: 0.9rem; transition: all 0.2s;
  }
  .tech:hover { border-color: #667eea; background: #1e1e48; }

  /* API links */
  .api-section { text-align: center; }
  .api-links { display: flex; flex-wrap: wrap; gap: 16px; justify-content: center; margin-top: 20px; }
  .btn {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 14px 28px; border-radius: 10px; font-size: 1rem; font-weight: 600;
    text-decoration: none; transition: all 0.2s; cursor: pointer;
  }
  .btn-primary { background: #667eea; color: #fff; }
  .btn-primary:hover { background: #5a6fd6; transform: translateY(-1px); }
  .btn-secondary { background: #2a2a5e; color: #e0e0e0; }
  .btn-secondary:hover { background: #3a3a7e; transform: translateY(-1px); }

  /* Status */
  .status-bar {
    display: inline-flex; align-items: center; gap: 8px;
    background: #1a3a1a; border: 1px solid #2a5a2a; border-radius: 20px;
    padding: 6px 18px; font-size: 0.85rem; color: #6f6;
  }
  .status-dot {
    width: 8px; height: 8px; border-radius: 50%; background: #0f0;
    animation: pulse 2s infinite;
  }
  @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.4; } }

  /* Test accounts */
  .accounts { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
  .account {
    background: #1a1a3e; border: 1px solid #2a2a5e; border-radius: 10px; padding: 16px; text-align: center;
  }
  .account .name { font-weight: 700; font-size: 1.05rem; }
  .account .pass { font-size: 0.8rem; color: #8888aa; font-family: 'Courier New', monospace; }

  /* Footer */
  footer {
    text-align: center; padding: 32px 0; font-size: 0.85rem;
    color: #666; border-top: 1px solid #1a1a3e;
  }

  @media (max-width: 600px) {
    header { padding: 48px 0 40px; }
    header h1 { font-size: 2rem; }
    .features { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>

<header>
  <div class="container">
    <span class="badge">v1.0 · 全栈即时通讯</span>
    <h1>Chat<span>App</span></h1>
    <p>基于 FastAPI + WebSocket + Flutter 构建的即时通讯云平台，支持文字、图片、语音、视频聊天及朋友圈社交。</p>
    <div class="status-bar">
      <span class="status-dot"></span>
      <span>服务运行中</span>
    </div>
  </div>
</header>

<section>
  <div class="container">
    <h2>核心功能</h2>
    <div class="features">
      <div class="card">
        <div class="icon">💬</div>
        <h3>实时聊天</h3>
        <p>基于 WebSocket 的全双工通信，消息实时推送零延迟。支持文字、图片、语音、视频多种消息类型。</p>
      </div>
      <div class="card">
        <div class="icon">👥</div>
        <h3>好友系统</h3>
        <p>搜索用户、发送好友请求、同意/拒绝，好友列表实时更新，完整的社交关系管理。</p>
      </div>
      <div class="card">
        <div class="icon">📱</div>
        <h3>朋友圈</h3>
        <p>发布图文动态，分页浏览好友动态，支持点赞评论，记录分享生活点滴。</p>
      </div>
      <div class="card">
        <div class="icon">🔐</div>
        <h3>安全认证</h3>
        <p>JWT 令牌认证 + bcrypt 密码加密，7 天自动登录，WebSocket 连接 Token 验证。</p>
      </div>
      <div class="card">
        <div class="icon">📁</div>
        <h3>文件上传</h3>
        <p>支持图片、语音、视频文件上传，50MB 限制，按类型分类存储。</p>
      </div>
      <div class="card">
        <div class="icon">📱</div>
        <h3>Flutter 跨平台</h3>
        <p>一套代码编译 Android APK，Provider 状态管理，Dio HTTP 客户端，响应式 UI。</p>
      </div>
    </div>
  </div>
</section>

<section>
  <div class="container">
    <h2>技术栈</h2>
    <div class="tech-list">
      <div class="tech">FastAPI</div>
      <div class="tech">Python 3.12</div>
      <div class="tech">WebSocket</div>
      <div class="tech">SQLAlchemy 2.0</div>
      <div class="tech">PostgreSQL</div>
      <div class="tech">JWT</div>
      <div class="tech">bcrypt</div>
      <div class="tech">Flutter</div>
      <div class="tech">Dart</div>
      <div class="tech">Provider</div>
      <div class="tech">Dio</div>
      <div class="tech">RESTful API</div>
    </div>
  </div>
</section>

<section>
  <div class="container api-section">
    <h2 style="justify-content: center;">API 交互文档</h2>
    <p style="color: #a0a0c0; margin-bottom: 8px;">
      所有 API 端点可在 Swagger UI 中在线调试 — 注册、登录、发消息、好友操作全部可交互操作。
    </p>
    <div class="api-links">
      <a href="/docs" class="btn btn-primary" target="_blank">
        📖 Swagger API 文档
      </a>
      <a href="/redoc" class="btn btn-secondary" target="_blank">
        📄 ReDoc 文档
      </a>
    </div>
  </div>
</section>

<section>
  <div class="container">
    <h2>测试账号</h2>
    <p style="color: #a0a0c0; margin-bottom: 20px;">
      通过 Swagger 文档可直接使用以下账号测试全部功能：
    </p>
    <div class="accounts">
      <div class="account">
        <div class="name">Alice</div>
        <div class="pass">alice / alice123</div>
        <div style="font-size:0.8rem; color:#666; margin-top:6px;">全栈开发者</div>
      </div>
      <div class="account">
        <div class="name">Bob</div>
        <div class="pass">bob / bob123</div>
        <div style="font-size:0.8rem; color:#666; margin-top:6px;">产品设计师</div>
      </div>
      <div class="account">
        <div class="name">Charlie</div>
        <div class="pass">charlie / charlie123</div>
        <div style="font-size:0.8rem; color:#666; margin-top:6px;">自由职业者</div>
      </div>
    </div>
  </div>
</section>

<footer>
  <div class="container">
    ChatApp v1.0 · FastAPI + Flutter 全栈即时通讯<br>
    <span style="font-size:0.75rem;">Powered by FastAPI · Swagger UI · Uvicorn</span>
  </div>
</footer>

</body>
</html>\
"""
