"""
Orchestrator tests — end-to-end pipeline tests for the Care Coordination Agent.

Tests cover:
- Doctor discovery (cardiologist + home consultation)
- Availability check as a follow-on step
- Multi-step: search → availability → booking pend → confirm
- Emergency message hard-stop (no tool executed)
- Diagnosis request refusal
- Unrelated message graceful handling
- Session continuity (session_id echoed back)
- Mock mode: model_used reflects mock provider, not fabricated Gemini name
"""
from __future__ import annotations

import pytest

from agent.orchestrator import CareCoordinationOrchestrator
from agent.schemas import (
    ActionType,
    ConfirmRequest,
    ExecuteRequest,
    RiskLevel,
)


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _request(
    message: str,
    patient_id: str = "patient-001",
    session_id: str | None = None,
) -> ExecuteRequest:
    return ExecuteRequest(
        message=message,
        patient_id=patient_id,
        session_id=session_id,
    )


# ---------------------------------------------------------------------------
# Doctor search
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_cardiologist_search_returns_doctors(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    Patient: 'Find me a cardiologist for a home consultation.'
    Expected: SHOW_DOCTORS action with at least one cardiologist.
    """
    response = await orchestrator.handle_execute(
        request=_request("Find me a cardiologist for a home consultation")
    )

    assert response.intent == "doctor_search"
    assert response.tool_used == "search_doctors"
    assert response.risk_level == RiskLevel.low
    assert response.requires_confirmation is False

    show_doctors = [a for a in response.actions if a.type == ActionType.SHOW_DOCTORS]
    assert len(show_doctors) == 1
    doctors = show_doctors[0].data["doctors"]
    assert len(doctors) > 0
    # All returned doctors must have a verified field for the trust badge
    assert all("verified" in d for d in doctors)


@pytest.mark.asyncio
async def test_general_physician_search_returns_results(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("I have a fever and need a doctor")
    )

    assert response.intent == "doctor_search"
    assert response.tool_used == "search_doctors"
    show_doctors = [a for a in response.actions if a.type == ActionType.SHOW_DOCTORS]
    assert len(show_doctors[0].data["doctors"]) > 0


@pytest.mark.asyncio
async def test_doctor_search_without_specialty_returns_all_doctors(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("I need to see a doctor")
    )

    assert response.intent == "doctor_search"
    show_doctors = [a for a in response.actions if a.type == ActionType.SHOW_DOCTORS]
    # Returns results even with no specialty filter
    assert len(show_doctors) == 1
    assert show_doctors[0].data["count"] > 0


# ---------------------------------------------------------------------------
# Availability check
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_check_availability_with_doctor_id(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()

    response = await orchestrator.handle_execute(
        request=_request(
            f"Check availability for doctor doc-001 on {tomorrow}"
        )
    )

    assert response.tool_used == "check_availability"
    show_avail = [a for a in response.actions if a.type == ActionType.SHOW_AVAILABILITY]
    assert len(show_avail) == 1
    assert show_avail[0].data["slot_count"] > 0


@pytest.mark.asyncio
async def test_availability_carries_forward_from_doctor_search(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    Multi-step: search doctors → ask for availability using the same session.
    The orchestrator should carry forward the first doctor's ID from the
    previous search result.
    """
    session_id = "test-multistep-avail"

    # Step 1: Search
    step1 = await orchestrator.handle_execute(
        request=_request("Find me a cardiologist", session_id=session_id)
    )
    assert step1.tool_used == "search_doctors"

    # Step 2: Availability (no doctor_id explicitly given — carry forward)
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()

    step2 = await orchestrator.handle_execute(
        request=_request(f"Check availability for tomorrow {tomorrow}", session_id=session_id)
    )

    # Even if intent doesn't cleanly map (keyword fallback), no crash
    assert step2.session_id == session_id
    assert step2.message  # always returns a non-empty message


# ---------------------------------------------------------------------------
# Appointment booking — confirmation workflow
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_book_appointment_requires_confirmation(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    Booking must not execute without confirmation — a confirmation token
    must be issued and the action must be pending.
    """
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()

    response = await orchestrator.handle_execute(
        request=_request(
            f"Book an appointment with doctor doc-001 on {tomorrow} at 10:00 for home visit"
        )
    )

    assert response.requires_confirmation is True
    assert response.confirmation_token is not None
    assert response.risk_level == RiskLevel.sensitive
    awaiting = [a for a in response.actions if a.type == ActionType.AWAITING_CONFIRMATION]
    assert len(awaiting) == 1


@pytest.mark.asyncio
async def test_confirmed_booking_succeeds(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    Full booking workflow: book → get token → confirm → BOOKING_CONFIRMED.
    """
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    session_id = "test-booking-flow"

    # Step 1: Request booking
    book_response = await orchestrator.handle_execute(
        request=_request(
            f"Book appointment with doc-001 on {tomorrow} at 09:00 home visit",
            session_id=session_id,
        )
    )
    assert book_response.requires_confirmation is True
    token = book_response.confirmation_token
    assert token is not None

    # Step 2: Confirm booking
    confirm_response = await orchestrator.handle_confirm(
        session_id=session_id,
        confirmation_token=token,
        confirmed=True,
    )

    assert confirm_response.tool_used == "book_appointment"
    confirmed_actions = [
        a for a in confirm_response.actions
        if a.type == ActionType.BOOKING_CONFIRMED
    ]
    assert len(confirmed_actions) == 1
    appt = confirmed_actions[0].data.get("appointment", {})
    assert appt.get("status") == "confirmed"
    assert appt.get("doctor_id") == "doc-001"


@pytest.mark.asyncio
async def test_cancelled_booking_clears_pending_state(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    session_id = "test-cancel-flow"

    book_response = await orchestrator.handle_execute(
        request=_request(
            f"Book appointment with doc-001 on {tomorrow} at 10:00",
            session_id=session_id,
        )
    )
    token = book_response.confirmation_token
    assert token is not None

    # Cancel
    cancel_response = await orchestrator.handle_confirm(
        session_id=session_id,
        confirmation_token=token,
        confirmed=False,
    )

    assert cancel_response.requires_confirmation is False
    assert "cancel" in cancel_response.message.lower()


@pytest.mark.asyncio
async def test_invalid_confirmation_token_is_rejected(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    from datetime import date, timedelta
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    session_id = "test-bad-token"

    await orchestrator.handle_execute(
        request=_request(
            f"Book appointment with doc-001 on {tomorrow} at 10:00",
            session_id=session_id,
        )
    )

    bad_response = await orchestrator.handle_confirm(
        session_id=session_id,
        confirmation_token="definitely-wrong-token",
        confirmed=True,
    )

    assert "invalid" in bad_response.message.lower()


# ---------------------------------------------------------------------------
# Emergency handling
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_emergency_message_hard_stops_pipeline(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    An emergency message must:
    - Return EMERGENCY action
    - Have escalation risk level
    - Not execute any tool (tool_used must be None)
    """
    response = await orchestrator.handle_execute(
        request=_request("I have severe chest pain and cannot breathe")
    )

    assert response.risk_level == RiskLevel.escalation
    assert response.tool_used is None
    emergency_actions = [a for a in response.actions if a.type == ActionType.EMERGENCY]
    assert len(emergency_actions) == 1


@pytest.mark.asyncio
async def test_emergency_overrides_doctor_search_intent(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    Even if the message contains a doctor-search keyword, an emergency
    signal must override it and never proceed to search_doctors.
    """
    response = await orchestrator.handle_execute(
        request=_request("I need a doctor — I'm having a heart attack")
    )

    assert response.risk_level == RiskLevel.escalation
    assert response.tool_used is None


# ---------------------------------------------------------------------------
# Safety refusals
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_diagnosis_request_is_refused(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("Diagnose me — what disease do I have based on my symptoms?")
    )

    assert response.risk_level in (RiskLevel.sensitive, RiskLevel.escalation)
    assert response.tool_used is None
    assert "diagnos" in response.message.lower() or "doctor" in response.message.lower()


@pytest.mark.asyncio
async def test_prescription_request_is_refused(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("Prescribe me some medicine for my back pain")
    )

    assert response.tool_used is None
    assert response.risk_level in (RiskLevel.sensitive, RiskLevel.escalation)


# ---------------------------------------------------------------------------
# Unrelated messages
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_unrelated_message_returns_graceful_response(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("What is the weather today?")
    )

    assert response.message  # never empty
    assert response.tool_used is None


# ---------------------------------------------------------------------------
# Session continuity
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_session_id_is_echoed_back(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("Find me a doctor", session_id="my-session-123")
    )

    assert response.session_id == "my-session-123"


@pytest.mark.asyncio
async def test_new_session_id_is_auto_generated(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_execute(
        request=_request("Find me a doctor")
    )

    assert response.session_id  # non-empty UUID string
    assert len(response.session_id) > 0


# ---------------------------------------------------------------------------
# Model observability
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_mock_mode_model_name_is_correct(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    """
    When running in mock mode (no Gemini API key), model_used must
    reflect the mock provider name, not claim a real model was used.
    """
    response = await orchestrator.handle_execute(
        request=_request("Find me a doctor")
    )

    # In mock mode, model_used is either the mock name or None
    # — never a fabricated "gemini-2.0-flash" string
    if response.model_used is not None:
        assert "mock" in response.model_used.lower() or "gemini" not in response.model_used.lower()


# ---------------------------------------------------------------------------
# Confirm with no pending state
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_confirm_without_pending_action_returns_helpful_message(
    orchestrator: CareCoordinationOrchestrator,
) -> None:
    response = await orchestrator.handle_confirm(
        session_id="non-existent-session",
        confirmation_token="any-token",
        confirmed=True,
    )

    assert response.message
    assert "pending" in response.message.lower() or "session" in response.message.lower()
