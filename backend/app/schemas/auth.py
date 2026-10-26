from __future__ import annotations

from pydantic import BaseModel, Field

from app.core.security import UserRole


class RegisterRequest(BaseModel):
    phone: str = Field(min_length=6, max_length=20)
    password: str = Field(min_length=6)
    display_name: str
    role: UserRole = UserRole.patient


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: UserRole
    user_id: str
