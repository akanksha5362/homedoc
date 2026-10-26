"""
Tool Registry + Permission Manager combined (Day 3.2 §14/§15). The agent
orchestrator never calls a tool object directly — only through
`ToolRegistry.execute(...)`, which is where the permission chain
(Authentication -> Role -> Authorization) is actually enforced in code.

An LLM can SUGGEST a tool name; it cannot make this registry skip a check.
If the LLM hallucinates a tool name that doesn't exist, or that the
caller's role isn't allowed to use, this raises ToolPermissionError —
which is a HARD stop, not something the orchestrator can talk its way
around.
"""
from __future__ import annotations

from typing import Any

from app.ai.audit.logger import audit_tool_call
from app.ai.tools.base import AgentTool, ToolContext, ToolResult
from app.ai.tools.get_patient_profile_tool import GetPatientProfileTool
from app.ai.tools.search_doctors_tool import SearchDoctorsTool
from app.core.errors import ToolPermissionError


class ToolRegistry:
    def __init__(self, tools: list[AgentTool] | None = None):
        self._tools: dict[str, AgentTool] = {t.name: t for t in (tools or _default_tools())}

    def get(self, name: str) -> AgentTool | None:
        return self._tools.get(name)

    def list_names(self) -> list[str]:
        return list(self._tools.keys())

    async def execute(
        self, *, tool_name: str, context: ToolContext, arguments: dict[str, Any]
    ) -> ToolResult:
        tool = self._tools.get(tool_name)

        if tool is None:
            # The LLM asked for a tool that doesn't exist — never treat
            # this as "close enough, run something similar." Hard stop.
            audit_tool_call(tool_name=tool_name, user_id=context.user_id, allowed=False, reason="unknown_tool")
            raise ToolPermissionError(f"Unknown tool: {tool_name}")

        if context.role not in tool.allowed_roles:
            audit_tool_call(
                tool_name=tool_name, user_id=context.user_id, allowed=False, reason="role_not_permitted"
            )
            raise ToolPermissionError(f"Role {context.role.value} is not permitted to use {tool_name}")

        audit_tool_call(tool_name=tool_name, user_id=context.user_id, allowed=True, reason="ok")
        return await tool.run(context=context, arguments=arguments)


def _default_tools() -> list[AgentTool]:
    return [
        SearchDoctorsTool(),
        GetPatientProfileTool(),
    ]
