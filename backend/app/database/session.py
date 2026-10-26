"""
Database session foundation (Day 3.2 §5, "PostgreSQL connection
foundation"). Uses SQLAlchemy 2.0's ORM, dialect-agnostic — the same code
runs against SQLite (local dev/tests, zero setup) or PostgreSQL (staging/
production) purely based on `DATABASE_URL`. Nothing above this module
should import a Postgres-specific driver directly.
"""
from __future__ import annotations

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

_connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}

engine = create_engine(settings.database_url, connect_args=_connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency — one session per request, always closed."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Creates tables from the ORM models. Fine for local dev/tests;
    production should use real migrations (Alembic) — not built today,
    flagged as Day 4+ scope per the backend structure's `database/
    migrations/` placeholder.
    """
    from app.database import models  # noqa: F401  (ensures models are registered)

    Base.metadata.create_all(bind=engine)
