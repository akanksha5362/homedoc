"""
Tool-level tests — unit tests for each individual tool.

Tests cover:
- search_doctors: with/without specialty, consultation_type filter
- check_availability: known doctor, missing doctor_id/date
- book_appointment: without confirmation (gate check), with confirmation
- get_patient_records: own record, cross-patient access denied
- get_prescriptions: own prescriptions, cross-patient denied
- schedule_followup: creates a reminder, defaults on missing fields
- Registry: unknown tool name rejected, role not permitted rejected
"""
from __future__ import annotations

from datetime import date, timedelta

import pytest

from agent.tools.appointment_tools import BookAppointmentTool
from agent.tools.base import ToolCallContext, ToolResult
from agent.tools.doctor_tools import CheckAvailabilityTool, SearchDoctorsTool
from agent.tools.patient_tools import GetPatientRecordsTool, GetPrescriptionsTool
from agent.tools.reminder_tools import ScheduleFollowupTool
from agent.tools.registry import ToolRegistry


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _patient_context(patient_id: str = "patient-001") -> ToolCallContext:
    return ToolCallContext(
        user_id=patient_id,
        role="patient",
        patient_id=patient_id,
    )


def _doctor_context(user_id: str = "doc-001") -> ToolCallContext:
    return ToolCallContext(
        user_id=user_id,
        role="doctor",
        patient_id="patient-001",
    )


def _tomorrow() -> str:
    return (date.today() + timedelta(days=1)).isoformat()


# ---------------------------------------------------------------------------
# search_doctors
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_search_doctors_returns_all_when_no_filter(
    doctor_service,
) -> None:
    tool = SearchDoctorsTool(doctor_service=doctor_service)
    result = await tool.execute(context=_patient_context(), arguments={})

    assert result.success is True
    assert "doctors" in result.data
    assert result.data["count"] > 0


@pytest.mark.asyncio
async def test_search_doctors_filters_by_specialty(
    doctor_service,
) -> None:
    tool = SearchDoctorsTool(doctor_service=doctor_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"specialty": "Cardiology"},
    )

    assert result.success is True
    doctors = result.data["doctors"]
    assert all("cardio" in d["specialty"].lower() for d in doctors)


@pytest.mark.asyncio
async def test_search_doctors_filters_home_visit(
    doctor_service,
) -> None:
    tool = SearchDoctorsTool(doctor_service=doctor_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"consultation_type": "home_visit"},
    )

    assert result.success is True
    doctors = result.data["doctors"]
    assert all(d["supports_home_visit"] is True for d in doctors)


@pytest.mark.asyncio
async def test_search_doctors_specialty_with_no_matches_returns_empty(
    doctor_service,
) -> None:
    tool = SearchDoctorsTool(doctor_service=doctor_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"specialty": "NonExistentSpecialty12345"},
    )

    assert result.success is True
    assert result.data["count"] == 0


# ---------------------------------------------------------------------------
# check_availability
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_check_availability_returns_slots_for_known_doctor(
    appointment_service,
) -> None:
    tool = CheckAvailabilityTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"doctor_id": "doc-001", "date": _tomorrow()},
    )

    assert result.success is True
    assert result.data["slot_count"] > 0
    assert result.data["doctor_id"] == "doc-001"


@pytest.mark.asyncio
async def test_check_availability_missing_doctor_id_returns_error(
    appointment_service,
) -> None:
    tool = CheckAvailabilityTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"date": _tomorrow()},
    )

    assert result.success is False
    assert result.error == "missing_parameter"


@pytest.mark.asyncio
async def test_check_availability_missing_date_returns_error(
    appointment_service,
) -> None:
    tool = CheckAvailabilityTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"doctor_id": "doc-001"},
    )

    assert result.success is False
    assert result.error == "missing_parameter"


@pytest.mark.asyncio
async def test_check_availability_unknown_doctor_returns_empty_slots(
    appointment_service,
) -> None:
    tool = CheckAvailabilityTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={"doctor_id": "doc-not-real", "date": _tomorrow()},
    )

    assert result.success is True
    assert result.data["slot_count"] == 0


# ---------------------------------------------------------------------------
# book_appointment
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_book_appointment_without_confirmation_returns_gate_error(
    appointment_service,
) -> None:
    """
    Booking without confirmed=True must return requires_confirmation error,
    not execute the booking. This is the confirmation gate test.
    """
    tool = BookAppointmentTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={
            "doctor_id": "doc-001",
            "date": _tomorrow(),
            "slot": "10:00",
            "consultation_type": "home_visit",
            # confirmed is missing / False
        },
    )

    assert result.success is False
    assert result.error == "requires_confirmation"
    # The pending booking details must be in the result for the
    # orchestrator to issue a confirmation token
    assert "pending_booking" in result.data


@pytest.mark.asyncio
async def test_book_appointment_with_confirmation_succeeds(
    appointment_service,
) -> None:
    tool = BookAppointmentTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={
            "doctor_id": "doc-001",
            "date": _tomorrow(),
            "slot": "09:00",
            "consultation_type": "home_visit",
            "confirmed": True,
        },
    )

    assert result.success is True
    appt = result.data.get("appointment", {})
    assert appt.get("doctor_id") == "doc-001"
    assert appt.get("status") == "confirmed"
    assert appt.get("patient_id") == "patient-001"


@pytest.mark.asyncio
async def test_book_appointment_with_unknown_doctor_fails(
    appointment_service,
) -> None:
    tool = BookAppointmentTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={
            "doctor_id": "doc-does-not-exist",
            "date": _tomorrow(),
            "slot": "10:00",
            "consultation_type": "video",
            "confirmed": True,
        },
    )

    assert result.success is False
    assert result.error == "booking_failed"


@pytest.mark.asyncio
async def test_book_appointment_missing_required_fields_fails(
    appointment_service,
) -> None:
    tool = BookAppointmentTool(appointment_service=appointment_service)
    result = await tool.execute(
        context=_patient_context(),
        arguments={
            "confirmed": True,
            # doctor_id, date, slot all missing
        },
    )

    assert result.success is False
    assert result.error == "missing_parameters"


# ---------------------------------------------------------------------------
# get_patient_records
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_get_patient_records_own_record_succeeds(
    patient_service,
) -> None:
    tool = GetPatientRecordsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={"patient_id": "patient-001"},
    )

    assert result.success is True
    records = result.data.get("patient_records", {})
    assert records.get("patient_id") == "patient-001"
    assert "medical_history" in records


@pytest.mark.asyncio
async def test_get_patient_records_cross_patient_access_denied(
    patient_service,
) -> None:
    """
    A patient requesting another patient's records must be denied.
    This validates the defence-in-depth access control in the tool.
    """
    tool = GetPatientRecordsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),  # caller is patient-001
        arguments={"patient_id": "patient-002"},  # requesting patient-002
    )

    assert result.success is False
    assert result.error == "permission_denied"


@pytest.mark.asyncio
async def test_get_patient_records_doctor_can_access_any_patient(
    patient_service,
) -> None:
    """Doctors can access any patient's records (mock policy)."""
    tool = GetPatientRecordsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_doctor_context(),
        arguments={"patient_id": "patient-001"},
    )

    assert result.success is True


@pytest.mark.asyncio
async def test_get_patient_records_unknown_patient_returns_not_found(
    patient_service,
) -> None:
    tool = GetPatientRecordsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_doctor_context(),
        arguments={"patient_id": "patient-9999"},
    )

    assert result.success is False
    assert result.error == "not_found"


# ---------------------------------------------------------------------------
# get_prescriptions
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_get_prescriptions_returns_own_prescriptions(
    patient_service,
) -> None:
    tool = GetPrescriptionsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={},
    )

    assert result.success is True
    assert result.data["count"] >= 2  # patient-001 has 2 prescriptions in mock data
    assert isinstance(result.data["prescriptions"], list)


@pytest.mark.asyncio
async def test_get_prescriptions_cross_patient_denied(
    patient_service,
) -> None:
    tool = GetPrescriptionsTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={"patient_id": "patient-002"},
    )

    assert result.success is False
    assert result.error == "permission_denied"


@pytest.mark.asyncio
async def test_get_prescriptions_empty_for_no_records(
    patient_service,
) -> None:
    tool = GetPrescriptionsTool(patient_service=patient_service)
    # patient-002 has only 1 prescription
    result = await tool.execute(
        context=_doctor_context(),
        arguments={"patient_id": "patient-002"},
    )

    assert result.success is True
    assert result.data["count"] == 1


# ---------------------------------------------------------------------------
# schedule_followup
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_schedule_followup_creates_reminder(
    patient_service,
) -> None:
    tool = ScheduleFollowupTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={
            "message": "Follow-up with cardiologist",
            "reminder_time": "2026-11-10T09:00:00",
        },
    )

    assert result.success is True
    reminder = result.data.get("reminder", {})
    assert reminder.get("patient_id") == "patient-001"
    assert reminder.get("status") == "scheduled"
    assert reminder.get("message") == "Follow-up with cardiologist"


@pytest.mark.asyncio
async def test_schedule_followup_defaults_when_message_missing(
    patient_service,
) -> None:
    tool = ScheduleFollowupTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={},  # no message, no time
    )

    assert result.success is True
    reminder = result.data.get("reminder", {})
    assert reminder.get("message")  # defaults to non-empty string


@pytest.mark.asyncio
async def test_schedule_followup_with_appointment_id(
    patient_service,
) -> None:
    tool = ScheduleFollowupTool(patient_service=patient_service)
    result = await tool.execute(
        context=_patient_context("patient-001"),
        arguments={
            "message": "Pre-appointment reminder",
            "reminder_time": "2026-11-05T08:00:00",
            "appointment_id": "appt-fake-123",
        },
    )

    assert result.success is True
    assert result.data["reminder"]["appointment_id"] == "appt-fake-123"


# ---------------------------------------------------------------------------
# Tool Registry
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_registry_rejects_unknown_tool(tool_registry: ToolRegistry) -> None:
    context = _patient_context()
    result = await tool_registry.execute(
        tool_name="delete_all_records",
        context=context,
        arguments={},
    )

    assert result.success is False
    assert result.error == "unknown_tool"


@pytest.mark.asyncio
async def test_registry_rejects_wrong_role(tool_registry: ToolRegistry) -> None:
    """book_appointment is not allowed for the 'doctor' role."""
    context = ToolCallContext(
        user_id="doc-001",
        role="doctor",
        patient_id="patient-001",
    )
    result = await tool_registry.execute(
        tool_name="book_appointment",
        context=context,
        arguments={"confirmed": True},
    )

    assert result.success is False
    assert result.error == "permission_denied"


@pytest.mark.asyncio
async def test_registry_lists_all_expected_tools(tool_registry: ToolRegistry) -> None:
    expected = {
        "search_doctors",
        "check_availability",
        "book_appointment",
        "get_patient_records",
        "get_prescriptions",
        "schedule_followup",
    }
    assert set(tool_registry.list_names()) == expected
