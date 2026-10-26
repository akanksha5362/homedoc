from __future__ import annotations

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database.session import Base


@pytest.fixture()
def db_session():
    """A fresh in-memory SQLite database per test — no shared state,
    no dependency on a real Postgres instance for the test suite.
    """
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    from app.database import models  # noqa: F401 register models

    Base.metadata.create_all(bind=engine)
    session_local = sessionmaker(bind=engine)
    session = session_local()
    try:
        yield session
    finally:
        session.close()
