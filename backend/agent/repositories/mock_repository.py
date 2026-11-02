"""
In-memory mock repositories for standalone testing and development.

All data here is FICTIONAL and used only for testing the agent's logic.
No patient privacy concerns — this data ships with the codebase and
is never connected to real users.

[INTEGRATION POINT: Replace MockDoctorRepository with a real implementation
 that wraps the existing DoctorRepository (app/database/repositories/doctor_repository.py)
 or calls the doctor API endpoint.]

[INTEGRATION POINT: Replace MockAppointmentRepository with an implementation
 that connects to the existing appointment APIs once they are built.]

[INTEGRATION POINT: Replace MockPatientRepository with an implementation
 that calls authenticated backend services with proper consent checks.]

[INTEGRATION POINT: Replace MockReminderRepository with an implementation
 that connects to the existing notification services.]
"""
from __future__ import annotations

import uuid
from copy import deepcopy
from datetime import date, datetime, timedelta
from typing import Any

from agent.repositories.base import (
    AppointmentRepositoryBase,
    DoctorRepositoryBase,
    PatientRepositoryBase,
    ReminderRepositoryBase,
)

# ---------------------------------------------------------------------------
# Seed data — fictional, for testing only
# ---------------------------------------------------------------------------

_MOCK_DOCTORS: list[dict[str, Any]] = [
    {
        "id": "doc-001",
        "name": "Dr. Priya Nair",
        "specialty": "Cardiology",
        "verified": True,
        "rating": 4.9,
        "experience_years": 14,
        "supports_home_visit": True,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Mumbai",
        "languages": ["English", "Hindi", "Malayalam"],
        "fee_home_visit": 1200,
        "fee_video": 600,
    },
    {
        "id": "doc-002",
        "name": "Dr. Arjun Mehta",
        "specialty": "Cardiology",
        "verified": True,
        "rating": 4.7,
        "experience_years": 10,
        "supports_home_visit": False,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Mumbai",
        "languages": ["English", "Hindi", "Gujarati"],
        "fee_home_visit": None,
        "fee_video": 500,
    },
    {
        "id": "doc-003",
        "name": "Dr. Ananya Sharma",
        "specialty": "General Physician",
        "verified": True,
        "rating": 4.8,
        "experience_years": 9,
        "supports_home_visit": True,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Delhi",
        "languages": ["English", "Hindi"],
        "fee_home_visit": 800,
        "fee_video": 400,
    },
    {
        "id": "doc-004",
        "name": "Dr. Fatima Sheikh",
        "specialty": "Pediatrics",
        "verified": True,
        "rating": 4.9,
        "experience_years": 12,
        "supports_home_visit": True,
        "supports_video": False,
        "supports_clinic": True,
        "location": "Delhi",
        "languages": ["English", "Hindi", "Urdu"],
        "fee_home_visit": 900,
        "fee_video": None,
    },
    {
        "id": "doc-005",
        "name": "Dr. Rajesh Kumar",
        "specialty": "Dermatology",
        "verified": True,
        "rating": 4.6,
        "experience_years": 8,
        "supports_home_visit": False,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Bangalore",
        "languages": ["English", "Hindi", "Kannada"],
        "fee_home_visit": None,
        "fee_video": 550,
    },
    {
        "id": "doc-006",
        "name": "Dr. Meera Iyer",
        "specialty": "Neurology",
        "verified": True,
        "rating": 4.8,
        "experience_years": 15,
        "supports_home_visit": True,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Chennai",
        "languages": ["English", "Tamil"],
        "fee_home_visit": 1500,
        "fee_video": 700,
    },
    {
        "id": "doc-007",
        "name": "Dr. Sanjay Patel",
        "specialty": "Orthopedics",
        "verified": True,
        "rating": 4.7,
        "experience_years": 11,
        "supports_home_visit": False,
        "supports_video": True,
        "supports_clinic": True,
        "location": "Ahmedabad",
        "languages": ["English", "Hindi", "Gujarati"],
        "fee_home_visit": None,
        "fee_video": 600,
    },
]

# Mock patient records — fictional data for two test patients
_MOCK_PATIENTS: dict[str, dict[str, Any]] = {
    "patient-001": {
        "patient_id": "patient-001",
        "name": "Test Patient One",
        "age": 35,
        "blood_group": "O+",
        "allergies": ["Penicillin"],
        "chronic_conditions": ["Hypertension"],
        "medical_history": [
            {
                "date": "2026-09-15",
                "doctor": "Dr. Ananya Sharma",
                "specialty": "General Physician",
                "diagnosis": "Viral fever",
                "notes": "Rest advised, paracetamol prescribed",
            },
            {
                "date": "2026-06-10",
                "doctor": "Dr. Priya Nair",
                "specialty": "Cardiology",
                "diagnosis": "Routine cardiac check",
                "notes": "ECG normal, continue current medication",
            },
        ],
    },
    "patient-002": {
        "patient_id": "patient-002",
        "name": "Test Patient Two",
        "age": 28,
        "blood_group": "A+",
        "allergies": [],
        "chronic_conditions": [],
        "medical_history": [
            {
                "date": "2026-10-01",
                "doctor": "Dr. Fatima Sheikh",
                "specialty": "Pediatrics",
                "diagnosis": "Child health check",
                "notes": "Routine visit, all normal",
            }
        ],
    },
}

# Mock prescriptions
_MOCK_PRESCRIPTIONS: dict[str, list[dict[str, Any]]] = {
    "patient-001": [
        {
            "prescription_id": "rx-001",
            "date": "2026-09-15",
            "doctor": "Dr. Ananya Sharma",
            "medications": [
                {
                    "name": "Paracetamol 500mg",
                    "dosage": "1 tablet every 6 hours",
                    "duration": "3 days",
                    "instructions": "Take after food",
                }
            ],
            "status": "completed",
        },
        {
            "prescription_id": "rx-002",
            "date": "2026-06-10",
            "doctor": "Dr. Priya Nair",
            "medications": [
                {
                    "name": "Amlodipine 5mg",
                    "dosage": "1 tablet daily",
                    "duration": "Ongoing",
                    "instructions": "Take in the morning",
                }
            ],
            "status": "active",
        },
    ],
    "patient-002": [
        {
            "prescription_id": "rx-003",
            "date": "2026-10-01",
            "doctor": "Dr. Fatima Sheikh",
            "medications": [],
            "status": "completed",
            "notes": "No medication required",
        }
    ],
}


# ---------------------------------------------------------------------------
# Mock implementations
# ---------------------------------------------------------------------------

class MockDoctorRepository(DoctorRepositoryBase):
    """
    In-memory doctor store.

    [INTEGRATION POINT: Replace MockDoctorRepository with a real
     implementation that calls the existing DoctorRepository or doctor APIs.]
    """

    def search(
        self,
        *,
        specialty: str | None = None,
        consultation_type: str | None = None,
        location: str | None = None,
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        results = deepcopy(_MOCK_DOCTORS)

        if specialty:
            sl = specialty.lower()
            results = [
                d for d in results
                if sl in d["specialty"].lower()
            ]

        if consultation_type == "home_visit":
            results = [d for d in results if d["supports_home_visit"]]
        elif consultation_type == "video":
            results = [d for d in results if d["supports_video"]]

        if location:
            ll = location.lower()
            results = [d for d in results if ll in d["location"].lower()]

        results.sort(key=lambda d: d["rating"], reverse=True)
        return results[:limit]

    def get_by_id(self, doctor_id: str) -> dict[str, Any] | None:
        for doc in _MOCK_DOCTORS:
            if doc["id"] == doctor_id:
                return deepcopy(doc)
        return None


class MockAppointmentRepository(AppointmentRepositoryBase):
    """
    In-memory appointment store. Generates synthetic available slots.

    [INTEGRATION POINT: Replace with real appointment API calls.]
    """

    def __init__(self) -> None:
        # appointment_id -> appointment dict
        self._bookings: dict[str, dict[str, Any]] = {}

    def get_availability(
        self, *, doctor_id: str, date: str
    ) -> list[dict[str, Any]]:
        """Generate mock available slots for a doctor on a given date."""
        # Find doctor
        doctor = None
        for d in _MOCK_DOCTORS:
            if d["id"] == doctor_id:
                doctor = d
                break

        if not doctor:
            return []

        # Generate time slots: 09:00-17:00, hourly
        slots = []
        base_slots = [
            "09:00", "10:00", "11:00", "12:00",
            "14:00", "15:00", "16:00", "17:00",
        ]

        # Check which slots are already booked
        booked_slots = {
            b["slot"]
            for b in self._bookings.values()
            if b["doctor_id"] == doctor_id and b["date"] == date
        }

        for slot_time in base_slots:
            if slot_time not in booked_slots:
                slots.append({
                    "doctor_id": doctor_id,
                    "doctor_name": doctor["name"],
                    "date": date,
                    "slot": slot_time,
                    "consultation_types": (
                        ["home_visit", "video", "clinic"]
                        if doctor["supports_home_visit"] and doctor["supports_video"]
                        else (
                            ["video", "clinic"]
                            if doctor["supports_video"]
                            else ["clinic"]
                        )
                    ),
                })

        return slots

    def book(
        self,
        *,
        doctor_id: str,
        patient_id: str,
        slot: str,
        consultation_type: str,
        date: str,
    ) -> dict[str, Any]:
        """Book an appointment. Returns the booking record."""
        doctor = None
        for d in _MOCK_DOCTORS:
            if d["id"] == doctor_id:
                doctor = d
                break

        if not doctor:
            raise ValueError(f"Doctor {doctor_id} not found")

        appointment_id = f"appt-{str(uuid.uuid4())[:8]}"
        booking = {
            "appointment_id": appointment_id,
            "doctor_id": doctor_id,
            "doctor_name": doctor["name"],
            "specialty": doctor["specialty"],
            "patient_id": patient_id,
            "date": date,
            "slot": slot,
            "consultation_type": consultation_type,
            "status": "confirmed",
            "booked_at": datetime.utcnow().isoformat(),
        }
        self._bookings[appointment_id] = booking
        return deepcopy(booking)

    def get_by_patient(self, *, patient_id: str) -> list[dict[str, Any]]:
        return [
            deepcopy(b)
            for b in self._bookings.values()
            if b["patient_id"] == patient_id
        ]


class MockPatientRepository(PatientRepositoryBase):
    """
    In-memory patient records store.

    [INTEGRATION POINT: Replace with calls to authenticated backend patient
     services — always enforce consent and role-based access control.]
    """

    def get_records(self, *, patient_id: str) -> dict[str, Any] | None:
        return deepcopy(_MOCK_PATIENTS.get(patient_id))

    def get_prescriptions(self, *, patient_id: str) -> list[dict[str, Any]]:
        return deepcopy(_MOCK_PRESCRIPTIONS.get(patient_id, []))


class MockReminderRepository(ReminderRepositoryBase):
    """
    In-memory reminder store.

    [INTEGRATION POINT: Replace with calls to the existing notification
     services — connect successful bookings and reminders to push
     notifications, SMS, or email via the notification module.]
    """

    def __init__(self) -> None:
        self._reminders: list[dict[str, Any]] = []

    def create(
        self,
        *,
        patient_id: str,
        message: str,
        reminder_time: str,
        appointment_id: str | None = None,
    ) -> dict[str, Any]:
        reminder = {
            "reminder_id": f"rem-{str(uuid.uuid4())[:8]}",
            "patient_id": patient_id,
            "message": message,
            "reminder_time": reminder_time,
            "appointment_id": appointment_id,
            "created_at": datetime.utcnow().isoformat(),
            "status": "scheduled",
        }
        self._reminders.append(reminder)
        return deepcopy(reminder)

    def get_by_patient(self, *, patient_id: str) -> list[dict[str, Any]]:
        return [
            deepcopy(r)
            for r in self._reminders
            if r["patient_id"] == patient_id
        ]


# ---------------------------------------------------------------------------
# Singleton instances for injection — tests can replace these
# ---------------------------------------------------------------------------

_doctor_repo = MockDoctorRepository()
_appointment_repo = MockAppointmentRepository()
_patient_repo = MockPatientRepository()
_reminder_repo = MockReminderRepository()


def get_doctor_repository() -> MockDoctorRepository:
    return _doctor_repo


def get_appointment_repository() -> MockAppointmentRepository:
    return _appointment_repo


def get_patient_repository() -> MockPatientRepository:
    return _patient_repo


def get_reminder_repository() -> MockReminderRepository:
    return _reminder_repo
