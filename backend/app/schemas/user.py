import datetime
from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=128)
    nickname: str | None = None


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    username: str


class UserResponse(BaseModel):
    id: int
    username: str
    nickname: str | None
    avatar_url: str | None
    bio: str | None
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    nickname: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
