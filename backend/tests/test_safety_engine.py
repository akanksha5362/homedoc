from __future__ import annotations

from app.ai.agent.intents import IntentExtraction
from app.ai.safety.policy import SafetyEngine
from app.schemas.agent import RiskLevel


def test_emergency_signal_overrides_everything():
    engine = SafetyEngine()
    intent = IntentExtraction(intent="doctor_search", emergency_signal=True)

    decision = engine.evaluate(intent=intent, tool_name="search_doctors")

    assert decision.allowed is False
    assert decision.risk_level == RiskLevel.escalation
    assert decision.requires_confirmation is True


def test_low_risk_tool_does_not_require_confirmation():
    engine = SafetyEngine()
    intent = IntentExtraction(intent="doctor_search")

    decision = engine.evaluate(intent=intent, tool_name="search_doctors")

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.low
    assert decision.requires_confirmation is False


def test_sensitive_tool_always_requires_confirmation():
    engine = SafetyEngine()
    intent = IntentExtraction(intent="book_appointment")

    decision = engine.evaluate(intent=intent, tool_name="book_appointment")

    assert decision.risk_level == RiskLevel.sensitive
    assert decision.requires_confirmation is True


def test_unclassified_tool_defaults_to_confirm_not_silent_allow():
    """A tool added later without updating the safety policy must fail
    toward caution, not silently execute without confirmation.
    """
    engine = SafetyEngine()
    intent = IntentExtraction(intent="something_new")

    decision = engine.evaluate(intent=intent, tool_name="some_future_tool")

    assert decision.allowed is True
    assert decision.requires_confirmation is True


def test_no_tool_selected_is_info_level():
    engine = SafetyEngine()
    intent = IntentExtraction(intent="unknown")

    decision = engine.evaluate(intent=intent, tool_name=None)

    assert decision.risk_level == RiskLevel.info
    assert decision.requires_confirmation is False
