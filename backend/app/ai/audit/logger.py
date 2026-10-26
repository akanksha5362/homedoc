"""
AI Audit Logger (Day 3.2 §10/§31). Separate from general app logging
because tool-call audit records are a compliance/security artifact, not
just a debugging aid — every agent action that touched (or tried to
touch) a permission boundary is recorded here.

Foundation-stage storage: in-memory list + structured log line. A real
deployment should persist this to the `audit_logs` table already defined
in Architecture v1 §J — not built today (no repository for it exists yet);
flagged as Day 4+ scope.
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field

from app.core.logging import log_ai_event


@dataclass
class AuditEntry:
    tool_name: str
    user_id: str
    allowed: bool
    reason: str
    timestamp: float = field(default_factory=time.time)


_audit_trail: list[AuditEntry] = []


def audit_tool_call(*, tool_name: str, user_id: str, allowed: bool, reason: str) -> None:
    entry = AuditEntry(tool_name=tool_name, user_id=user_id, allowed=allowed, reason=reason)
    _audit_trail.append(entry)
    log_ai_event(
        "tool_call_audit",
        tool_name=tool_name,
        user_id=user_id,
        allowed=allowed,
        reason=reason,
    )


def get_audit_trail() -> list[AuditEntry]:
    """Test/inspection hook — not exposed via any API route."""
    return list(_audit_trail)
