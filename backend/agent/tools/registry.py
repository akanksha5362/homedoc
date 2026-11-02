"""
Tool Registry — the ONLY entry point for tool execution.

The orchestrator never imports or instantiates tools directly — it calls
ToolRegistry.execute(), which enforces:
1. Allowlist check: tool must exist in the registry (LLM cannot hallucinate
   a tool name into existence).
2. Role check: caller's role must be in tool.allowed_roles.
3. Audit logging: every call (allowed or denied) is logged.
4. Exception isolation: tool exceptions are caught and returned as
   ToolResult(success=False) — orchestrator never sees raw exceptions.

An LLM can SUGGEST a tool name; it cannot bypass this registry.
"""
from __future__ import annotations

import traceback
from typing import Any

from app.core.logging import get_logger

from agent.services.appointment_service import AppointmentService
from agent.services.doctor_service import DoctorService
from agent.services.patient_service import PatientService
from agent.tools.appointment_tools import BookAppointmentTool
from agent.tools.base import AgentTool, ToolCallContext, ToolResult
from agent.tools.doctor_tools import CheckAvailabilityTool, SearchDoctorsTool
from agent.tools.patient_tools import GetPatientRecordsTool, GetPrescriptionsTool
from agent.tools.reminder_tools import ScheduleFollowupTool

logger = get_logger("homedoc.agent.tool_registry")


class ToolPermissionError(Exception):
    """Raised when a tool call is denied — unknown tool or role not permitted."""


class ToolRegistry:
    """
    Allowlist-based tool registry and executor.

    Tools are registered at construction time. Any tool name not in the
    registry is rejected — no path exists for arbitrary code execution.
    """

    def __init__(
        self,
        doctor_service: DoctorService,
        appointment_service: AppointmentService,
        patient_service: PatientService,
    ) -> None:
        tools: list[AgentTool] = [
            SearchDoctorsTool(doctor_service=doctor_service),
            CheckAvailabilityTool(appointment_service=appointment_service),
            BookAppointmentTool(appointment_service=appointment_service),
            GetPatientRecordsTool(patient_service=patient_service),
            GetPrescriptionsTool(patient_service=patient_service),
            ScheduleFollowupTool(patient_service=patient_service),
        ]
        self._tools: dict[str, AgentTool] = {t.name: t for t in tools}

    def list_names(self) -> list[str]:
        return list(self._tools.keys())

    def get(self, name: str) -> AgentTool | None:
        return self._tools.get(name)

    async def execute(
        self,
        *,
        tool_name: str,
        context: ToolCallContext,
        arguments: dict[str, Any],
    ) -> ToolResult:
        """
        Execute a tool after permission checks.

        Returns ToolResult — never raises. Permission denials are returned
        as ToolResult(success=False, error="permission_denied").
        """
        # --- Allowlist check ---
        tool = self._tools.get(tool_name)
        if tool is None:
        logger.warning("tool_registry_unknown_tool tool_name=%s user_id=%s", tool_name, context.user_id)
            return ToolResult(
                success=False,
                error="unknown_tool",
                data={"requested": tool_name, "available": self.list_names()},
            )

        # --- Role check ---
        if context.role not in tool.allowed_roles:
        logger.warning("tool_registry_role_denied tool_name=%s user_id=%s role=%s", tool_name, context.user_id, context.role)
            return ToolResult(
                success=False,
                error="permission_denied",
                data={
                    "message": (
                        f"Role '{context.role}' is not permitted to use '{tool_name}'."
                    )
                },
            )

        logger.info(
            "tool_registry_executing",
            tool_name=tool_name,
            user_id=context.user_id,
            role=context.role,
        )

        # --- Execute with exception isolation ---
        try:
            result = await tool.execute(context=context, arguments=arguments)
            logger.info(
                "tool_registry_result",
                tool_name=tool_name,
                success=result.success,
                error=result.error,
            )
            return result
        except Exception as exc:  # noqa: BLE001
            logger.error(
                "tool_registry_exception",
                tool_name=tool_name,
                error_type=type(exc).__name__,
                traceback=traceback.format_exc(),
            )
            return ToolResult(
                success=False,
                error="tool_execution_error",
                data={"message": "Tool execution failed unexpectedly."},
            )
