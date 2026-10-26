from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.deps import get_db
from app.database.session import Base


@pytest.fixture()
def client():
    """Full app, but with an isolated in-memory SQLite database injected
    via dependency override — never touches the dev SQLite file on disk.

    StaticPool is required here: plain `sqlite:///:memory:` gives each new
    connection its own empty database, and FastAPI's `get_db` dependency
    opens a new connection per request — without StaticPool, every request
    would see a fresh, table-less database.
    """
    from app.main import app

    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    from app.database import models  # noqa: F401

    Base.metadata.create_all(bind=engine)
    testing_session_local = sessionmaker(bind=engine)

    def _override_get_db():
        db = testing_session_local()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_register_then_login(client):
    register = client.post(
        "/auth/register",
        json={"phone": "+919999911111", "password": "secretpass", "display_name": "Test User"},
    )
    assert register.status_code == 200
    assert "access_token" in register.json()

    login = client.post("/auth/login", json={"phone": "+919999911111", "password": "secretpass"})
    assert login.status_code == 200
    assert login.json()["role"] == "patient"


def test_login_with_wrong_password_fails(client):
    client.post(
        "/auth/register",
        json={"phone": "+919999922222", "password": "correctpass", "display_name": "Test User 2"},
    )
    response = client.post("/auth/login", json={"phone": "+919999922222", "password": "wrongpass"})
    assert response.status_code == 401


def test_doctors_requires_authentication(client):
    response = client.get("/doctors")
    assert response.status_code == 401


def test_full_flow_register_then_search_doctors_then_agent(client):
    register = client.post(
        "/auth/register",
        json={"phone": "+919999933333", "password": "secretpass", "display_name": "Flow User"},
    )
    token = register.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    doctors_response = client.get("/doctors", headers=headers)
    assert doctors_response.status_code == 200
    assert len(doctors_response.json()) > 0

    agent_response = client.post(
        "/ai/agent",
        headers=headers,
        json={"message": "I have a fever and want to see a doctor"},
    )
    assert agent_response.status_code == 200
    body = agent_response.json()
    assert body["actions"][0]["type"] == "SHOW_DOCTORS"
    assert body["risk_level"] == "low"
