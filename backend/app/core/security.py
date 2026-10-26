"""
Authentication primitives (Day 3.2 §7): password hashing + JWT issuing/
verification. Role-based authorization is enforced in api/deps.py on top
of what this module decodes — never in the Flutter client.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from enum import Enum

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserRole(str, Enum):
    patient = "patient"
    doctor = "doctor"
    admin = "admin"


def hash_password(plain: str) -> str:
    return _pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


def create_access_token(*, subject: str, role: UserRole) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expiry_minutes)
    payload = {"sub": subject, "role": role.value, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


class DecodedToken:
    __slots__ = ("user_id", "role")

    def __init__(self, user_id: str, role: UserRole):
        self.user_id = user_id
        self.role = role


def decode_access_token(token: str) -> DecodedToken | None:
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except JWTError:
        return None
    user_id = payload.get("sub")
    role_value = payload.get("role")
    if user_id is None or role_value is None:
        return None
    try:
        role = UserRole(role_value)
    except ValueError:
        return None
    return DecodedToken(user_id=user_id, role=role)
