"""
Agent tool foundation (Day 3.2 §14). Every tool the agent can call
implements this interface. Tools are the ONLY way the agent touches
HomeDoc data (Day 3.2 §30) — there is no path from the agent to the
database or any service that skips a Tool + its permission check.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any

from app.core.security import UserRole


@dataclass
class ToolContext:
    """Who is calling, and with what already-authenticated identity.
    Tools receive this instead of raw request data so they can never be
    tricked by LLM-generated input into acting as a different user
    (Day 3.2 §15: "must not access another patient's records").
    """
    user_id: str
    role: UserRole
    db_session: Any  # SQLAlchemy Session — typed loosely here to avoid a
                      # circular import; concrete tools import Session directly.


@dataclass
class ToolResult:
    success: bool
    data: dict[str, Any] = field(default_factory=dict)
    error: str | None = None


class AgentTool(ABC):
    name: str
    description: str
    # Roles allowed to invoke this tool at all — checked BEFORE the tool
    # body runs, by the ToolRegistry, not by the tool itself (Day 3.2 §15
    # permission chain: Authentication -> Role -> Authorization -> ...).
    allowed_roles: tuple[UserRole, ...] = (UserRole.patient, UserRole.doctor, UserRole.admin)

    @abstractmethod
    async def run(self, *, context: ToolContext, arguments: dict[str, Any]) -> ToolResult:
        raise NotImplementedError
