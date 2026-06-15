"""初始化演示数据 — Render 部署时自动运行"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from app.database import engine, Base, SessionLocal
from app.utils.security import hash_password

# 建表
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# 检查是否已有数据
existing = db.execute(text("SELECT COUNT(*) FROM users")).scalar()
if existing and existing > 0:
    print("✅ 数据库已有数据，跳过 seed")
    db.close()
    exit(0)

from app.models import User, Message, Post, Friendship
from app.models.friendship import FriendStatus

# ===== 用户 =====
alice = User(username="alice", password_hash=hash_password("alice123"),
             nickname="Alice", bio="全栈开发者，喜欢聊天")
bob = User(username="bob", password_hash=hash_password("bob123"),
           nickname="Bob", bio="产品设计师，热爱生活")
charlie = User(username="charlie", password_hash=hash_password("charlie123"),
               nickname="Charlie", bio="自由职业者")
db.add_all([alice, bob, charlie])
db.commit()

# ===== 好友关系 =====
friendships = [
    Friendship(user_id=alice.id, friend_id=bob.id, status=FriendStatus.ACCEPTED),
    Friendship(user_id=bob.id, friend_id=alice.id, status=FriendStatus.ACCEPTED),
    Friendship(user_id=alice.id, friend_id=charlie.id, status=FriendStatus.ACCEPTED),
    Friendship(user_id=charlie.id, friend_id=alice.id, status=FriendStatus.ACCEPTED),
]
db.add_all(friendships)
db.commit()

# ===== 消息 =====
messages = [
    Message(sender_id=bob.id, receiver_id=alice.id, content="嗨！最近在忙什么项目？"),
    Message(sender_id=alice.id, receiver_id=bob.id, content="在做一个即时通讯 App，就是咱们现在用的这个 😄"),
    Message(sender_id=bob.id, receiver_id=alice.id, content="哈哈，看起来不错啊！用的是什么技术栈？"),
    Message(sender_id=alice.id, receiver_id=bob.id, content="FastAPI + WebSocket + Flutter，实时通信效果很好"),
    Message(sender_id=bob.id, receiver_id=alice.id, content="什么时候上线？我要第一个下载！"),
    Message(sender_id=alice.id, receiver_id=bob.id, content="已经部署了，你可以试试看～"),
    Message(sender_id=charlie.id, receiver_id=alice.id, content="Alice，能帮我看看这个设计吗？"),
    Message(sender_id=alice.id, receiver_id=charlie.id, content="没问题，发过来看看！"),
]
db.add_all(messages)
db.commit()

# ===== 动态/朋友圈 =====
posts = [
    Post(user_id=alice.id, content="终于完成了 ChatApp 的部署！🎉 前后端全部上线，WebSocket 实时通信完美运行。"),
    Post(user_id=alice.id, content="今天学到了新的 Docker 技巧，容器化部署真方便。"),
    Post(user_id=bob.id, content="设计了一套新的 UI 组件库，Material 3 设计语言太优雅了。"),
    Post(user_id=bob.id, content="周末去看了个展，拍了很多好照片 📸"),
    Post(user_id=charlie.id, content="自由职业者的日常：写代码、喝咖啡、遛狗 ☕🐕"),
]
db.add_all(posts)
db.commit()

print("✅ ChatApp 演示数据初始化完成！")
print(f"   用户: alice / alice123")
print(f"   用户: bob / bob123")
print(f"   用户: charlie / charlie123")
db.close()
