"""
Appointment tools: book_appointment.

Safety rule: BookAppointmentTool will ONLY proceed when
`arguments["confirmed"] == True`. If not confirmed, it returns a
ToolResult(success=False, error="requires_confirmation") which the
orchestrator uses to enter the confirmation workflow.

The orchestrator is responsible for:
1. Detecting that confirmation is required.
2. Issuing a confirmation token and returning it to the client.
3. On the /agent/confirm endpoint, re-calling this tool with confirmed=True.

The tool itself never books without explicit confirmation — it does not
infer confirmation from context or LLM output.

[INTEGRATION POINT: Connect to the existing appointment API once built.
 After successful booking, trigger the notification service to send
 confirmation to patient and doctor.]
"""
from __future__ import annotations

from typing import Any

from agent.services.appointment_service import AppointmentService
from agent.tools.base import AgentTool, ToolCallContext, ToolResult


class BookAppointmentTool(AgentTool):
    """
    Book an appointment — only after explicit patient confirmation.

    This tool is classified as SENSITIVE in the safety layer and always
    requires a confirmation token before the booking is executed.

    Arguments expected:
        doctor_id (str): Target doctor
        date (str): YYYY-MM-DD
        slot (str): HH:MM time slot
        consultation_type (str): home_visit | video | clinic
        confirmed (bool): MUST be True for booking to proceed
    """
    name = "book_appointment"
    description = (
        "Book an appointment with a doctor. Requires explicit patient confirmation "
        "before booking is executed. Returns booking details on success."
    )
    allowed_roles = ("patient", "admin")

    def __init__(self, appointment_service: AppointmentService) -> None:
        self._service = appointment_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        # --- Confirmation gate — this is code, not an LLM instruction ---
        if not arguments.get("confirmed", False):
            # Return structured "needs confirmation" — orchestrator will
            # issue a token and wait for /agent/confirm before re-calling.
            return ToolResult(
                success=False,
                error="requires_confirmation",
                data={
                    "message": (
                        "Please confirm you want to book this appointment."
                    ),
                    "pending_booking": {
                        "doctor_id": arguments.get("doctor_id"),
                        "date": arguments.get("date"),
                        "slot": arguments.get("slot"),
                        "consultation_type": arguments.get(
                            "consultation_type", "video"
                        ),
                    },
                },
            )

        # --- Parameter validation ---
        doctor_id = arguments.get("doctor_id")
        date = arguments.get("date")
        slot = arguments.get("slot")
        consultation_type = arguments.get("consultation_type", "video")

        missing = [k for k, v in {
            "doctor_id": doctor_id,
            "date": date,
            "slot": slot,
        }.items() if not v]

        if missing:
            return ToolResult(
                success=False,
                error="missing_parameters",
                data={"missing": missing},
            )

        # --- Execute booking ---
        try:
            appointment = self._service.book(
                doctor_id=doctor_id,
                patient_id=context.patient_id,
                slot=slot,
                consultation_type=consultation_type,
                date=date,
            )
            return ToolResult(
                success=True,
                data={
                    "appointment": appointment,
                    "message": (
                        f"Appointment booked with {appointment['doctor_name']} "
                        f"on {date} at {slot} ({consultation_type})."
                    ),
                },
            )
        except ValueError as exc:
            return ToolResult(
                success=False,
                error="booking_failed",
                data={"message": str(exc)},
            )
