"""
Pydantic schemas for the standalone Care Coordination Agent (agent/).

These are separate from app/schemas/agent.py — they extend the contract with
multi-step workflow support (confirmation tokens, step tracking) and richer
entity extraction needed for the full coordination feature set.
"""
from __future__ import annotations

from datetime import date, datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Enumerations
# ---------------------------------------------------------------------------

class ConsultationType(str, Enum):
    home_visit = "home_visit"
    video = "video"
    clinic = "clinic"


class AgentIntent(str, Enum):
    doctor_search = "doctor_search"
    check_availability = "check_availability"
    book_appointment = "book_appointment"
    get_patient_records = "get_patient_records"
    get_prescriptions = "get_prescriptions"
    schedule_followup = "schedule_followup"
    emergency = "emergency"
    unknown = "unknown"


class ActionType(str, Enum):
    SHOW_DOCTORS = "SHOW_DOCTORS"
    SHOW_AVAILABILITY = "SHOW_AVAILABILITY"
    SHOW_PATIENT_RECORDS = "SHOW_PATIENT_RECORDS"
    SHOW_PRESCRIPTIONS = "SHOW_PRESCRIPTIONS"
    BOOKING_CONFIRMED = "BOOKING_CONFIRMED"
    REMINDER_SET = "REMINDER_SET"
    AWAITING_CONFIRMATION = "AWAITING_CONFIRMATION"
    EMERGENCY = "EMERGENCY"
    INFO = "INFO"


class RiskLevel(str, Enum):
    info = "info"
    low = "low"
    confirm = "confirm"
    sensitive = "sensitive"
    escalation = "escalation"


class WorkflowState(str, Enum):
    """Tracks where we are in a multi-step workflow."""
    idle = "idle"
    searching = "searching"
    awaiting_selection = "awaiting_selection"
    awaiting_confirmation = "awaiting_confirmation"
    completed = "completed"


# ---------------------------------------------------------------------------
# Structured intent extraction result
# ---------------------------------------------------------------------------

class ExtractedIntent(BaseModel):
    """Structured output of the intent processor. Never raw LLM text."""
    intent: AgentIntent = AgentIntent.unknown
    entities: dict[str, Any] = Field(default_factory=dict)
    # e.g. {"specialty": "Cardiology", "date": "2026-11-04",
    #        "consultation_type": "home_visit", "doctor_id": "...",
    #        "patient_id": "...", "reminder_time": "08:00"}
    confidence: float = Field(ge=0.0, le=1.0, default=0.0)
    emergency_signal: bool = False
    raw_text: str = ""  # stored for audit; never used for tool decisions


# ---------------------------------------------------------------------------
# Tool result
# ---------------------------------------------------------------------------

class ToolResult(BaseModel):
    success: bool
    data: dict[str, Any] = Field(default_factory=dict)
    error: str | None = None


# ---------------------------------------------------------------------------
# Agent action (structured, renderable by Flutter)
# ---------------------------------------------------------------------------

class AgentAction(BaseModel):
    type: ActionType
    data: dict[str, Any] = Field(default_factory=dict)


# ---------------------------------------------------------------------------
# API request/response shapes
# ---------------------------------------------------------------------------

class ExecuteRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    session_id: str | None = None
    # patient_id is taken from the auth token in production;
    # passed explicitly here so the standalone agent can be tested
    # without a JWT stack.
    # [INTEGRATION POINT: In production, derive patient_id from the
    #  authenticated JWT token via app/api/deps.py get_current_user —
    #  never trust a client-supplied patient_id.]
    patient_id: str = Field(default="patient-001")


class ConfirmRequest(BaseModel):
    session_id: str
    confirmation_token: str  # opaque token issued by the agent
    confirmed: bool = True   # False = cancel the pending action


class AgentStep(BaseModel):
    """One step in a multi-step workflow trace (for observability)."""
    step_index: int
    tool_used: str | None
    intent: str
    success: bool
    summary: str


class ExecuteResponse(BaseModel):
    message: str                                    # human-readable explanation
    intent: str
    risk_level: RiskLevel
    requires_confirmation: bool
    confirmation_token: str | None = None           # set when confirmation is needed
    actions: list[AgentAction] = Field(default_factory=list)
    workflow_steps: list[AgentStep] = Field(default_factory=list)
    session_id: str
    tool_used: str | None = None
    model_used: str | None = None


class HealthResponse(BaseModel):
    status: str
    version: str
    mock_mode: bool
    registered_tools: list[str]
    timestamp: str
