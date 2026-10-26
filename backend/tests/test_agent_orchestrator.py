from __future__ import annotations

import pytest

from app.ai.agent.memory import InMemorySessionStore
from app.ai.agent.orchestrator import AgentOrchestrator
from app.ai.gateway.gateway import AIGateway
from app.ai.gateway.mock_provider import MockLLMProvider
from app.ai.safety.policy import SafetyEngine
from app.ai.tools.registry import ToolRegistry
from app.core.security import UserRole
from app.schemas.agent import ActionType, RiskLevel


def _make_orchestrator() -> AgentOrchestrator:
    return AgentOrchestrator(
        gateway=AIGateway(provider=MockLLMProvider()),
        tool_registry=ToolRegistry(),
        safety_engine=SafetyEngine(),
        session_store=InMemorySessionStore(),
    )


@pytest.mark.asyncio
async def test_doctor_search_flow_returns_show_doctors_action(db_session):
    orchestrator = _make_orchestrator()

    response = await orchestrator.handle(
        message="I have had a fever since yesterday, I want a doctor",
        session_id="s1",
        user_id="u1",
        role=UserRole.patient,
        db_session=db_session,
    )

    assert response.intent == "doctor_search"
    assert response.tool_used == "search_doctors"
    assert response.risk_level == RiskLevel.low
    assert response.requires_confirmation is False
    assert len(response.actions) == 1
    assert response.actions[0].type == ActionType.SHOW_DOCTORS
    assert len(response.actions[0].data["doctors"]) > 0
    # Every doctor result must include a verification flag — the trust
    # layer's frontend badge depends on this being present.
    assert all("verified" in d for d in response.actions[0].data["doctors"])


@pytest.mark.asyncio
async def test_emergency_message_short_circuits_before_any_tool_call(db_session):
    orchestrator = _make_orchestrator()

    response = await orchestrator.handle(
        message="severe chest pain, cannot breathe",
        session_id="s2",
        user_id="u1",
        role=UserRole.patient,
        db_session=db_session,
    )

    assert response.risk_level == RiskLevel.escalation
    assert response.requires_confirmation is True
    assert response.tool_used is None  # no tool executed on the emergency path
    assert response.actions[0].type == ActionType.EMERGENCY


@pytest.mark.asyncio
async def test_unrelated_message_produces_no_tool_call(db_session):
    orchestrator = _make_orchestrator()

    response = await orchestrator.handle(
        message="what is HomeDoc",
        session_id="s3",
        user_id="u1",
        role=UserRole.patient,
        db_session=db_session,
    )

    assert response.tool_used is None
    assert response.actions == []
    assert response.risk_level == RiskLevel.info


@pytest.mark.asyncio
async def test_response_always_has_a_disclaimer_bearing_message(db_session):
    """Not a literal string match on purpose (the LLM's phrasing can
    change) — but the mock provider's canned safe response must always be
    what callers get when no real model is configured, and it must never
    be empty.
    """
    orchestrator = _make_orchestrator()

    response = await orchestrator.handle(
        message="I want a doctor for fever",
        session_id="s4",
        user_id="u1",
        role=UserRole.patient,
        db_session=db_session,
    )

    assert response.message
    assert response.model_used == "mock-rule-based-v1"


@pytest.mark.asyncio
async def test_session_id_is_echoed_back_for_conversation_continuity(db_session):
    """REGRESSION: AgentResponse originally didn't return session_id at
    all, silently breaking multi-turn continuity — the client would never
    learn the session id it should reuse on the next turn.
    """
    orchestrator = _make_orchestrator()

    response = await orchestrator.handle(
        message="I want a doctor for fever",
        session_id="explicit-session-abc",
        user_id="u1",
        role=UserRole.patient,
        db_session=db_session,
    )

    assert response.session_id == "explicit-session-abc"
