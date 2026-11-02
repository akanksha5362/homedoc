"""
Appointment Service — availability checking and booking logic.

[INTEGRATION POINT: Replace MockAppointmentRepository with a real
 implementation that connects to the existing appointment APIs once built.
 Availability and booking must always go through the service layer — tools
 never call the repository directly.]
"""
from __future__ import annotations

from typing import Any

from agent.repositories.base import AppointmentRepositoryBase


class AppointmentService:
    def __init__(self, repo: AppointmentRepositoryBase) -> None:
        self._repo = repo

    def get_availability(
        self, *, doctor_id: str, date: str
    ) -> list[dict[str, Any]]:
        """
        Return available time slots for a doctor on a given date.

        Returns empty list (not an error) if no slots are available.
        The tool layer treats an empty list as a valid "none available"
        result, not a failure.
        """
        return self._repo.get_availability(doctor_id=doctor_id, date=date)

    def book(
        self,
        *,
        doctor_id: str,
        patient_id: str,
        slot: str,
        consultation_type: str,
        date: str,
    ) -> dict[str, Any]:
        """
        Book an appointment. Called ONLY after explicit patient confirmation.

        Raises ValueError if the doctor_id is invalid.

        [INTEGRATION POINT: After successful booking, trigger the notification
         service to send a confirmation to the patient and the doctor.]
        """
        return self._repo.book(
            doctor_id=doctor_id,
            patient_id=patient_id,
            slot=slot,
            consultation_type=consultation_type,
            date=date,
        )

    def get_by_patient(self, *, patient_id: str) -> list[dict[str, Any]]:
        return self._repo.get_by_patient(patient_id=patient_id)
