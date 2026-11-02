"""
Base class for all Care Coordination Agent tools.

All tools in agent/tools/ implement this interface. The ToolRegistry is
the ONLY path through which the orchestrator calls a tool — there is no
direct import of tool classes in orchestrator.py.

Key invariants:
- Tools receive a ToolCallContext, never raw request data.
- Tools call their injected service, never a repository or DB directly.
- Tool.execute() is the only public entry point — no other methods are
  called by the registry.
- A tool that fails returns ToolResult(success=False, error=...) — it
  never raises an exception to the orchestrator (exceptions are caught
  in the registry).
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass
class ToolCallContext:
    """
    Authenticated caller context passed to every tool invocation.

    Tools use this to enforce row-level access control (e.g. a patient
    can only access their own records). This is NEVER derived from LLM
    output — it comes from the validated auth token.

    [INTEGRATION POINT: In production, populate user_id and role from the
     verified JWT token via app/api/deps.py:get_current_user. patient_id
     would be set to user_id for patient-role requests.]
    """
    user_id: str
    role: str           # "patient" | "doctor" | "admin"
    patient_id: str     # who the action is for (same as user_id for patients)


@dataclass
class ToolResult:
    success: bool
    data: dict[str, Any] = field(default_factory=dict)
    error: str | None = None


class AgentTool(ABC):
    """Abstract base for all agent tools."""
    name: str
    description: str
    # Roles that are allowed to call this tool at all.
    # Checked by ToolRegistry BEFORE the tool body runs.
    allowed_roles: tuple[str, ...] = ("patient", "doctor", "admin")

    @abstractmethod
    async def execute(
        self,
        *,
        context: ToolCallContext,
        arguments: dict[str, Any],
    ) -> ToolResult:
        raise NotImplementedError
