"""
Server-side auth dependencies (Day 3.2 §7: "Never trust the Flutter
client to enforce permissions"). Every protected route depends on
`get_current_user`, and role-restricted routes additionally depend on
`require_role(...)`.
"""
from __future__ import annotations

from collections.abc import Generator

from fastapi import Depends, Header
from sqlalchemy.orm import Session

from app.core.errors import AuthenticationAppError, AuthorizationAppError
from app.core.security import DecodedToken, UserRole, decode_access_token
from app.database.session import SessionLocal


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(authorization: str | None = Header(default=None)) -> DecodedToken:
    if authorization is None or not authorization.lower().startswith("bearer "):
        raise AuthenticationAppError("Missing or invalid Authorization header.")
    token = authorization.split(" ", 1)[1]
    decoded = decode_access_token(token)
    if decoded is None:
        raise AuthenticationAppError("Session expired or invalid. Please sign in again.")
    return decoded


def require_role(*roles: UserRole):
    def _dependency(user: DecodedToken = Depends(get_current_user)) -> DecodedToken:
        if user.role not in roles:
            raise AuthorizationAppError("You don't have permission to do that.")
        return user

    return _dependency
