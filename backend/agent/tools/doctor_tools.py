"""
Doctor tools: search_doctors and check_availability.

[INTEGRATION POINT: Replace MockDoctorRepository with the real DoctorRepository
 (app/database/repositories/doctor_repository.py) for production use.]

[INTEGRATION POINT: Connect availability and booking tools to the existing
 appointment APIs once they are built.]
"""
from __future__ import annotations

from typing import Any

from agent.services.appointment_service import AppointmentService
from agent.services.doctor_service import DoctorService
from agent.tools.base import AgentTool, ToolCallContext, ToolResult


class SearchDoctorsTool(AgentTool):
    """
    Search for doctors by specialization, location, and consultation type.

    This is a read-only, non-personal operation — no patient data is
    accessed. Allowed for all roles.

    [INTEGRATION POINT: Replace mock DoctorService with one backed by the
     existing doctor database/API.]
    """
    name = "search_doctors"
    description = (
        "Search for verified doctors by specialty, location, and consultation type "
        "(home_visit / video / clinic). Returns up to 5 matching doctors."
    )
    allowed_roles = ("patient", "doctor", "admin")

    def __init__(self, doctor_service: DoctorService) -> None:
        self._service = doctor_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        specialty = arguments.get("specialty")
        consultation_type = arguments.get("consultation_type")
        location = arguments.get("location")

        doctors = self._service.search(
            specialty=specialty,
            consultation_type=consultation_type,
            location=location,
            limit=5,
        )

        return ToolResult(
            success=True,
            data={
                "doctors": doctors,
                "count": len(doctors),
                "filters_applied": {
                    k: v for k, v in {
                        "specialty": specialty,
                        "consultation_type": consultation_type,
                        "location": location,
                    }.items() if v
                },
            },
        )


class CheckAvailabilityTool(AgentTool):
    """
    Retrieve available appointment slots for a given doctor and date.

    [INTEGRATION POINT: Connect to the existing appointment API for real
     slot availability once the appointment service is built.]
    """
    name = "check_availability"
    description = (
        "Check available appointment slots for a specific doctor on a given date. "
        "Requires doctor_id and date (YYYY-MM-DD)."
    )
    allowed_roles = ("patient", "doctor", "admin")

    def __init__(self, appointment_service: AppointmentService) -> None:
        self._service = appointment_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        doctor_id = arguments.get("doctor_id")
        date = arguments.get("date")

        if not doctor_id:
            return ToolResult(
                success=False,
                error="missing_parameter",
                data={"message": "doctor_id is required to check availability."},
            )

        if not date:
            return ToolResult(
                success=False,
                error="missing_parameter",
                data={"message": "date is required to check availability (YYYY-MM-DD)."},
            )

        slots = self._service.get_availability(doctor_id=doctor_id, date=date)

        return ToolResult(
            success=True,
            data={
                "doctor_id": doctor_id,
                "date": date,
                "available_slots": slots,
                "slot_count": len(slots),
            },
        )
