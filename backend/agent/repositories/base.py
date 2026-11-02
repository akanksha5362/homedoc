"""
Abstract repository interfaces for the Care Coordination Agent.

All concrete repositories (mock or real) must implement these interfaces.
Services talk to these abstractions — never to specific implementations.
This ensures that swapping the mock repository for a real database/API
repository requires only a single dependency injection change.

[INTEGRATION POINT: Real implementations will wrap the existing SQLAlchemy
 models and REST clients. The interface contract stays the same.]
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class DoctorRepositoryBase(ABC):
    @abstractmethod
    def search(
        self,
        *,
        specialty: str | None = None,
        consultation_type: str | None = None,
        location: str | None = None,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    def get_by_id(self, doctor_id: str) -> dict[str, Any] | None:
        raise NotImplementedError


class AppointmentRepositoryBase(ABC):
    @abstractmethod
    def get_availability(
        self, *, doctor_id: str, date: str
    ) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    def book(
        self,
        *,
        doctor_id: str,
        patient_id: str,
        slot: str,
        consultation_type: str,
        date: str,
    ) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def get_by_patient(self, *, patient_id: str) -> list[dict[str, Any]]:
        raise NotImplementedError


class PatientRepositoryBase(ABC):
    @abstractmethod
    def get_records(self, *, patient_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    @abstractmethod
    def get_prescriptions(self, *, patient_id: str) -> list[dict[str, Any]]:
        raise NotImplementedError


class ReminderRepositoryBase(ABC):
    @abstractmethod
    def create(
        self,
        *,
        patient_id: str,
        message: str,
        reminder_time: str,
        appointment_id: str | None = None,
    ) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def get_by_patient(self, *, patient_id: str) -> list[dict[str, Any]]:
        raise NotImplementedError
