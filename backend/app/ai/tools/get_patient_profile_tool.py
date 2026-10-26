"""
NOT IMPLEMENTED — deliberately a stub (Day 3.2 §14: "Do NOT necessarily
implement every tool today... create the architecture"). Registered so the
ToolRegistry's shape is real (permission checks, naming convention,
observability logging all exercise this like any other tool), but it
returns a clear failure rather than fabricating patient data. There is no
`patients` table yet — see database/models.py for what actually exists.
"""
from __future__ import annotations

from typing import Any

from app.ai.tools.base import AgentTool, ToolContext, ToolResult
from app.core.security import UserRole


class GetPatientProfileTool(AgentTool):
    name = "get_patient_profile"
    description = "Retrieve the authenticated patient's own profile. NOT YET IMPLEMENTED."
    allowed_roles = (UserRole.patient,)

    async def run(self, *, context: ToolContext, arguments: dict[str, Any]) -> ToolResult:
        return ToolResult(
            success=False,
            error="not_implemented",
            data={"message": "Patient profile retrieval is not implemented yet (Day 4+ scope)."},
        )
