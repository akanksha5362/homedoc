"""
ORM models — deliberately a SMALL subset of Architecture v1 §J's full
entity list: only what the Day 3.2 foundation and the one working agent
flow (doctor search) actually need. Adding `appointments`, `prescriptions`,
etc. as real tables is later-phase work — the entity design for those
already exists in Architecture v1 and isn't repeated here speculatively.
"""
from __future__ import annotations

import uuid

from sqlalchemy import Boolean, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.security import UserRole
from app.database.session import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    phone: Mapped[str] = mapped_column(String, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String)
    role: Mapped[str] = mapped_column(String, default=UserRole.patient.value)
    display_name: Mapped[str] = mapped_column(String)


class Doctor(Base):
    """Public-facing doctor profile fields only — matches Architecture v1
    §J's `doctors` entity, trimmed to what doctor search actually renders
    (DoctorCard in Flutter needs exactly these fields, no more).
    """
    __tablename__ = "doctors"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String)
    specialty: Mapped[str] = mapped_column(String, index=True)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    experience_years: Mapped[int] = mapped_column(Integer, default=0)
    supports_home_visit: Mapped[bool] = mapped_column(Boolean, default=True)
    supports_video: Mapped[bool] = mapped_column(Boolean, default=True)
    service_area: Mapped[str] = mapped_column(String, index=True, default="default")
