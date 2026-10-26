from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.errors import AuthenticationAppError, ValidationAppError
from app.core.security import UserRole, create_access_token, hash_password, verify_password
from app.database.models import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
def register(body: RegisterRequest, db: Session = Depends(get_db)) -> TokenResponse:
    existing = db.execute(select(User).where(User.phone == body.phone)).scalar_one_or_none()
    if existing is not None:
        raise ValidationAppError("An account with this phone number already exists.")

    user = User(
        phone=body.phone,
        hashed_password=hash_password(body.password),
        role=body.role.value,
        display_name=body.display_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(subject=user.id, role=UserRole(user.role))
    return TokenResponse(access_token=token, role=UserRole(user.role), user_id=user.id)


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.execute(select(User).where(User.phone == body.phone)).scalar_one_or_none()
    if user is None or not verify_password(body.password, user.hashed_password):
        raise AuthenticationAppError("Incorrect phone number or password.")

    token = create_access_token(subject=user.id, role=UserRole(user.role))
    return TokenResponse(access_token=token, role=UserRole(user.role), user_id=user.id)
