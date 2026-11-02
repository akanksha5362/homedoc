"""
Safety layer tests — policy engine and permission manager.

Tests cover:
- Emergency signal overrides all tool selection
- Sensitive tool (book_appointment) always requires confirmation
- Low-risk tools don't require confirmation
- Unclassified tools default to require confirmation (fail-toward-caution)
- Diagnosis request refused
- Prescription request refused
- No tool selected → info level, no confirmation
- Triage urgency override for high-urgency signals
- Permission manager: patient cross-record access
- Permission manager: unknown tool rejected
- Permission manager: role not permitted
"""
from __future__ import annotations

import pytest

from agent.safety.permission_manager import PermissionManager
from agent.safety.safety_manager import SafetyManager
from agent.schemas import AgentIntent, ExtractedIntent, RiskLevel


# ---------------------------------------------------------------------------
# SafetyManager
# ---------------------------------------------------------------------------

def test_emergency_signal_overrides_everything() -> None:
    """Emergency signal must block all tool execution, regardless of tool."""
    manager = SafetyManager()
    intent = ExtractedIntent(
        intent=AgentIntent.doctor_search,
        emergency_signal=True,
    )

    decision = manager.evaluate(
        intent=intent,
        tool_name="search_doctors",
        message="",
    )

    assert decision.allowed is False
    assert decision.risk_level == RiskLevel.escalation
    assert decision.requires_confirmation is True
    assert decision.reason == "emergency_signal_detected"


def test_emergency_intent_without_flag_also_blocked() -> None:
    """Emergency intent classification itself must also block execution."""
    manager = SafetyManager()
    intent = ExtractedIntent(
        intent=AgentIntent.emergency,
        emergency_signal=False,  # flag might be False but intent is emergency
    )

    decision = manager.evaluate(
        intent=intent,
        tool_name=None,
        message="",
    )

    assert decision.allowed is False
    assert decision.risk_level == RiskLevel.escalation


def test_book_appointment_always_requires_confirmation() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.book_appointment)

    decision = manager.evaluate(
        intent=intent,
        tool_name="book_appointment",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.sensitive
    assert decision.requires_confirmation is True


def test_search_doctors_is_low_risk_no_confirmation() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.doctor_search)

    decision = manager.evaluate(
        intent=intent,
        tool_name="search_doctors",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.low
    assert decision.requires_confirmation is False


def test_check_availability_is_low_risk_no_confirmation() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.check_availability)

    decision = manager.evaluate(
        intent=intent,
        tool_name="check_availability",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.low
    assert decision.requires_confirmation is False


def test_get_patient_records_is_info_level() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.get_patient_records)

    decision = manager.evaluate(
        intent=intent,
        tool_name="get_patient_records",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.info
    assert decision.requires_confirmation is False


def test_get_prescriptions_is_info_level() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.get_prescriptions)

    decision = manager.evaluate(
        intent=intent,
        tool_name="get_prescriptions",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.info
    assert decision.requires_confirmation is False


def test_schedule_followup_is_info_level() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.schedule_followup)

    decision = manager.evaluate(
        intent=intent,
        tool_name="schedule_followup",
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.info
    assert decision.requires_confirmation is False


def test_unclassified_tool_defaults_to_confirm_not_silent_allow() -> None:
    """
    A tool added without a safety classification must REQUIRE confirmation,
    not silently execute. Fail toward caution.
    """
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.unknown)

    decision = manager.evaluate(
        intent=intent,
        tool_name="some_future_unknown_tool",
        message="",
    )

    assert decision.allowed is True
    assert decision.requires_confirmation is True
    assert decision.risk_level == RiskLevel.confirm


def test_no_tool_selected_is_info_level_no_confirmation() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.unknown)

    decision = manager.evaluate(
        intent=intent,
        tool_name=None,
        message="",
    )

    assert decision.allowed is True
    assert decision.risk_level == RiskLevel.info
    assert decision.requires_confirmation is False


def test_diagnosis_request_in_message_is_refused() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.unknown)

    decision = manager.evaluate(
        intent=intent,
        tool_name=None,
        message="Diagnose me — what disease do I have?",
    )

    assert decision.allowed is False
    assert decision.reason == "diagnosis_request_refused"


def test_prescription_request_in_message_is_refused() -> None:
    manager = SafetyManager()
    intent = ExtractedIntent(intent=AgentIntent.unknown)

    decision = manager.evaluate(
        intent=intent,
        tool_name=None,
        message="prescribe me some medicine for this pain",
    )

    assert decision.allowed is False
    assert decision.reason == "prescription_request_refused"


def test_high_urgency_triage_overrides_routine_booking() -> None:
    """
    High-urgency triage results must override a pending booking workflow
    and redirect the patient to urgent care.

    [INTEGRATION POINT: This method is called when existing triage results
     are passed from the existing symptom triage system.]
    """
    manager = SafetyManager()
    override = manager.evaluate_triage_priority(
        triage_urgency="critical",
        pending_intent=AgentIntent.book_appointment,
    )

    assert override is not None
    assert override.allowed is False
    assert override.risk_level == RiskLevel.escalation
    assert override.reason == "triage_urgency_overrides_routine_workflow"


def test_low_urgency_triage_does_not_override() -> None:
    manager = SafetyManager()
    override = manager.evaluate_triage_priority(
        triage_urgency="low",
        pending_intent=AgentIntent.book_appointment,
    )

    assert override is None  # routine workflow can continue


def test_moderate_urgency_triage_does_not_override() -> None:
    manager = SafetyManager()
    override = manager.evaluate_triage_priority(
        triage_urgency="moderate",
        pending_intent=AgentIntent.book_appointment,
    )

    assert override is None


# ---------------------------------------------------------------------------
# PermissionManager
# ---------------------------------------------------------------------------

def test_permission_patient_can_access_own_records() -> None:
    pm = PermissionManager()
    decision = pm.check_tool_access(
        role="patient",
        tool_name="get_patient_records",
        user_id="patient-001",
        patient_id="patient-001",
        arguments={"patient_id": "patient-001"},
    )

    assert decision.allowed is True


def test_permission_patient_cross_record_access_denied() -> None:
    pm = PermissionManager()
    decision = pm.check_tool_access(
        role="patient",
        tool_name="get_patient_records",
        user_id="patient-001",
        patient_id="patient-001",
        arguments={"patient_id": "patient-002"},  # different patient
    )

    assert decision.allowed is False
    assert decision.reason == "cross_patient_access_denied"


def test_permission_doctor_can_access_patient_records() -> None:
    pm = PermissionManager()
    decision = pm.check_tool_access(
        role="doctor",
        tool_name="get_patient_records",
        user_id="doc-001",
        patient_id="patient-001",
        arguments={"patient_id": "patient-001"},
    )

    assert decision.allowed is True


def test_permission_doctor_cannot_book_appointment() -> None:
    """book_appointment is patient-only."""
    pm = PermissionManager()
    decision = pm.check_tool_access(
        role="doctor",
        tool_name="book_appointment",
        user_id="doc-001",
        patient_id="patient-001",
        arguments={},
    )

    assert decision.allowed is False
    assert decision.reason == "role_not_permitted"


def test_permission_unknown_tool_rejected() -> None:
    pm = PermissionManager()
    decision = pm.check_tool_access(
        role="admin",
        tool_name="drop_database",
        user_id="admin-001",
        patient_id="admin-001",
        arguments={},
    )

    assert decision.allowed is False
    assert decision.reason == "unknown_tool"


def test_permission_admin_can_access_all_allowed_tools() -> None:
    pm = PermissionManager()
    for tool_name in [
        "search_doctors",
        "check_availability",
        "book_appointment",
        "get_patient_records",
        "get_prescriptions",
        "schedule_followup",
    ]:
        decision = pm.check_tool_access(
            role="admin",
            tool_name=tool_name,
            user_id="admin-001",
            patient_id="patient-001",
            arguments={},
        )
        assert decision.allowed is True, f"Admin should be allowed to use {tool_name}"
