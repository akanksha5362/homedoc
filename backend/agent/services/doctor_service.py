"""
Doctor Service — business logic for doctor search and profile retrieval.

[INTEGRATION POINT: Replace MockDoctorRepository dependency with the real
 DoctorRepository (app/database/repositories/doctor_repository.py) or call
 the existing /doctors REST API. The service interface stays the same.]
"""
from __future__ import annotations

from typing import Any

from agent.repositories.base import DoctorRepositoryBase


class DoctorService:
    def __init__(self, repo: DoctorRepositoryBase) -> None:
        self._repo = repo

    def search(
        self,
        *,
        specialty: str | None = None,
        consultation_type: str | None = None,
        location: str | None = None,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        """
        Search for doctors matching the given criteria.

        Returns only fields safe to expose to patients — no internal IDs
        beyond the doctor_id needed for follow-up calls.
        """
        doctors = self._repo.search(
            specialty=specialty,
            consultation_type=consultation_type,
            location=location,
            limit=limit,
        )
        return doctors

    def get_by_id(self, doctor_id: str) -> dict[str, Any] | None:
        return self._repo.get_by_id(doctor_id)
