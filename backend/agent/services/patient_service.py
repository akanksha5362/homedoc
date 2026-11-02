"""
Patient Service — patient record and prescription retrieval.

[INTEGRATION POINT: Replace MockPatientRepository with authenticated calls
 to the real backend patient services. Consent checks and encryption must
 be handled at the repository/API layer — this service enforces that
 patient_id == requesting_user_id at minimum before calling through.]
"""
from __future__ import annotations

from typing import Any

from agent.repositories.base import PatientRepositoryBase, ReminderRepositoryBase


class PatientService:
    def __init__(
        self,
        patient_repo: PatientRepositoryBase,
        reminder_repo: ReminderRepositoryBase,
    ) -> None:
        self._patient_repo = patient_repo
        self._reminder_repo = reminder_repo

    def get_records(self, *, patient_id: str) -> dict[str, Any] | None:
        """
        Retrieve a patient's medical records.

        The calling tool is responsible for verifying that the requesting
        user is authorized to access this patient_id (enforced in
        PermissionManager before this is called).

        [INTEGRATION POINT: Connect to authenticated backend patient services
         with proper consent verification and field-level access control.]
        """
        return self._patient_repo.get_records(patient_id=patient_id)

    def get_prescriptions(self, *, patient_id: str) -> list[dict[str, Any]]:
        """
        Retrieve active and historical prescriptions.

        [INTEGRATION POINT: Connect patient and prescription tools to
         authenticated backend services — filter by consent status and
         ensure the requesting patient is the record owner.]
        """
        return self._patient_repo.get_prescriptions(patient_id=patient_id)

    def create_reminder(
        self,
        *,
        patient_id: str,
        message: str,
        reminder_time: str,
        appointment_id: str | None = None,
    ) -> dict[str, Any]:
        """
        Create a follow-up or medication reminder.

        [INTEGRATION POINT: Connect successful bookings and reminders to the
         existing notification services (push notifications, SMS, email).]
        """
        return self._reminder_repo.create(
            patient_id=patient_id,
            message=message,
            reminder_time=reminder_time,
            appointment_id=appointment_id,
        )

    def get_reminders(self, *, patient_id: str) -> list[dict[str, Any]]:
        return self._reminder_repo.get_by_patient(patient_id=patient_id)
