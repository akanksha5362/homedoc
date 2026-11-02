"""
Shared test fixtures for the Care Coordination Agent test suite.

All tests use:
- MockLLMProvider (deterministic, no GEMINI_API_KEY required)
- Fresh in-memory repositories per test (no shared state)
- Explicitly constructed orchestrators (no singleton reuse)

This ensures tests are reproducible, fast, and independent of:
- Network access
- A real Gemini API key
- The state of other tests
"""
from __future__ import annotations

import pytest

from app.ai.gateway.gateway import AIGateway
from app.ai.gateway.mock_provider import MockLLMProvider

from agent.intent_processor import IntentProcessor
from agent.orchestrator import CareCoordinationOrchestrator, InMemoryWorkflowStore
from agent.repositories.mock_repository import (
    MockAppointmentRepository,
    MockDoctorRepository,
    MockPatientRepository,
    MockReminderRepository,
)
from agent.response_generator import ResponseGenerator
from agent.safety.permission_manager import PermissionManager
from agent.safety.safety_manager import SafetyManager
from agent.services.appointment_service import AppointmentService
from agent.services.doctor_service import DoctorService
from agent.services.patient_service import PatientService
from agent.tools.registry import ToolRegistry


@pytest.fixture()
def mock_gateway() -> AIGateway:
    """Always uses MockLLMProvider — no network, no API key required."""
    return AIGateway(provider=MockLLMProvider())


@pytest.fixture()
def doctor_repo() -> MockDoctorRepository:
    return MockDoctorRepository()


@pytest.fixture()
def appointment_repo() -> MockAppointmentRepository:
    return MockAppointmentRepository()


@pytest.fixture()
def patient_repo() -> MockPatientRepository:
    return MockPatientRepository()


@pytest.fixture()
def reminder_repo() -> MockReminderRepository:
    return MockReminderRepository()


@pytest.fixture()
def doctor_service(doctor_repo: MockDoctorRepository) -> DoctorService:
    return DoctorService(repo=doctor_repo)


@pytest.fixture()
def appointment_service(appointment_repo: MockAppointmentRepository) -> AppointmentService:
    return AppointmentService(repo=appointment_repo)


@pytest.fixture()
def patient_service(
    patient_repo: MockPatientRepository,
    reminder_repo: MockReminderRepository,
) -> PatientService:
    return PatientService(patient_repo=patient_repo, reminder_repo=reminder_repo)


@pytest.fixture()
def tool_registry(
    doctor_service: DoctorService,
    appointment_service: AppointmentService,
    patient_service: PatientService,
) -> ToolRegistry:
    return ToolRegistry(
        doctor_service=doctor_service,
        appointment_service=appointment_service,
        patient_service=patient_service,
    )


@pytest.fixture()
def orchestrator(
    mock_gateway: AIGateway,
    tool_registry: ToolRegistry,
) -> CareCoordinationOrchestrator:
    return CareCoordinationOrchestrator(
        intent_processor=IntentProcessor(gateway=mock_gateway),
        tool_registry=tool_registry,
        safety_manager=SafetyManager(),
        permission_manager=PermissionManager(),
        response_generator=ResponseGenerator(gateway=mock_gateway),
        workflow_store=InMemoryWorkflowStore(),
    )
