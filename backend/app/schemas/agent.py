"""
Structured agent response (Day 3.2 §17). The agent NEVER returns only
plain text — every response is this shape, so Flutter can render the
right widget from `actions` instead of parsing free text.
"""
from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class RiskLevel(str, Enum):
    """Mirrors the Day 3.2 §16 action-risk levels. `info`/`low` never
    require confirmation; `sensitive`/`escalation` always do, and
    `escalation` additionally means the agent has stopped and handed off
    rather than completed an action itself.
    """
    info = "info"                # Level 0
    low = "low"                  # Level 1
    confirm = "confirm"          # Level 2
    sensitive = "sensitive"      # Level 3
    escalation = "escalation"    # Level 4


class ActionType(str, Enum):
    SHOW_DOCTORS = "SHOW_DOCTORS"
    SHOW_APPOINTMENTS = "SHOW_APPOINTMENTS"
    BOOK_APPOINTMENT = "BOOK_APPOINTMENT"
    SHOW_PRESCRIPTION = "SHOW_PRESCRIPTION"
    START_VIDEO = "START_VIDEO"
    TRACK_DOCTOR = "TRACK_DOCTOR"
    SET_REMINDER = "SET_REMINDER"
    REQUEST_HOME_VISIT = "REQUEST_HOME_VISIT"
    ESCALATE_TO_DOCTOR = "ESCALATE_TO_DOCTOR"
    EMERGENCY = "EMERGENCY"


class AgentAction(BaseModel):
    type: ActionType
    data: dict[str, Any] = Field(default_factory=dict)


class AgentRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    # Reserved for multi-turn context (Day 3.2 §22 session memory) — the
    # foundation stage is single-turn only; see AgentOrchestrator note.
    session_id: str | None = None


class AgentResponse(BaseModel):
    message: str
    intent: str
    risk_level: RiskLevel
    requires_confirmation: bool
    actions: list[AgentAction] = Field(default_factory=list)
    session_id: str

    # Observability/debugging fields — safe to expose to the client since
    # they contain no patient data, only which subsystems fired.
    tool_used: str | None = None
    model_used: str | None = None
