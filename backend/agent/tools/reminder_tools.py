"""
Reminder tool: schedule_followup.

Creates follow-up or medication reminders. Never auto-schedules without
the patient explicitly triggering the tool through the agent workflow.

[INTEGRATION POINT: Connect successful bookings and reminders to the
 existing notification services (push notifications, SMS, email) once
 the notification module is available.]
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from agent.services.patient_service import PatientService
from agent.tools.base import AgentTool, ToolCallContext, ToolResult


class ScheduleFollowupTool(AgentTool):
    """
    Create a follow-up visit or medication reminder.

    Arguments expected:
        message (str): What the reminder is about
        reminder_time (str): HH:MM or ISO datetime for the reminder
        appointment_id (str, optional): Link to a specific appointment

    [INTEGRATION POINT: Connect to the existing notification services to
     deliver reminders via push notification, SMS, or email.]
    """
    name = "schedule_followup"
    description = (
        "Create a follow-up appointment reminder or medication reminder "
        "for the authenticated patient."
    )
    allowed_roles = ("patient", "doctor", "admin")

    def __init__(self, patient_service: PatientService) -> None:
        self._service = patient_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        message = arguments.get("message")
        reminder_time = arguments.get("reminder_time")
        appointment_id = arguments.get("appointment_id")

        if not message:
            message = "Follow-up reminder"

        if not reminder_time:
            # Default: tomorrow at 09:00
            tomorrow = (date.today() + timedelta(days=1)).isoformat()
            reminder_time = f"{tomorrow}T09:00:00"

        try:
            reminder = self._service.create_reminder(
                patient_id=context.patient_id,
                message=message,
                reminder_time=reminder_time,
                appointment_id=appointment_id,
            )
            return ToolResult(
                success=True,
                data={
                    "reminder": reminder,
                    "message": (
                        f"Reminder '{reminder['message']}' scheduled for "
                        f"{reminder['reminder_time']}."
                    ),
                },
            )
        except Exception as exc:  # noqa: BLE001
            return ToolResult(
                success=False,
                error="reminder_failed",
                data={"message": str(exc)},
            )
