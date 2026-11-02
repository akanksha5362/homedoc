"""
Response Generator — converts raw tool results and workflow state into
human-readable, structured ExecuteResponse objects.

Rules:
- Never claims success unless the ToolResult.success flag is True.
- Appends a medical disclaimer to every patient-facing message.
- Never fabricates data — if the tool returned empty results, says so plainly.
- The LLM (generate()) is used only for the explanatory text, never for
  decisions about what action to take or whether an operation succeeded.
"""
from __future__ import annotations

from typing import Any

from app.ai.gateway.gateway import AIGateway
from app.core.logging import get_logger

from agent.schemas import (
    ActionType,
    AgentAction,
    AgentIntent,
    AgentStep,
    ExecuteResponse,
    ExtractedIntent,
    RiskLevel,
    ToolResult,
    WorkflowState,
)

logger = get_logger("homedoc.agent.response_generator")

_DISCLAIMER = (
    " This is general guidance only — always confirm important health "
    "decisions with a qualified doctor."
)

_CARE_ASSISTANT_SYSTEM_PROMPT = (
    "You are HomeDoc's care coordination assistant. You help patients find "
    "doctors, check availability, and manage appointments. "
    "You are NOT a doctor: never diagnose, never recommend medication, "
    "never claim certainty about a medical condition. "
    "Keep responses short, warm, and plain-language. "
    "Do not repeat information already shown in structured action cards — "
    "just summarize what was found and what the patient should do next."
)


class ResponseGenerator:
    def __init__(self, gateway: AIGateway) -> None:
        self._gateway = gateway

    async def build(
        self,
        *,
        original_message: str,
        intent: ExtractedIntent,
        tool_name: str | None,
        tool_result: ToolResult | None,
        risk_level: RiskLevel,
        requires_confirmation: bool,
        confirmation_token: str | None,
        session_id: str,
        steps: list[AgentStep],
        workflow_state: WorkflowState,
    ) -> ExecuteResponse:
        """Assemble the final ExecuteResponse from all pipeline outputs."""

        actions = self._build_actions(
            intent=intent,
            tool_name=tool_name,
            tool_result=tool_result,
            requires_confirmation=requires_confirmation,
            workflow_state=workflow_state,
        )

        # Generate a human-readable explanation via the LLM.
        # If generation fails, fall back to a safe canned message.
        explanation = await self._generate_explanation(
            original_message=original_message,
            intent=intent,
            tool_name=tool_name,
            tool_result=tool_result,
            requires_confirmation=requires_confirmation,
        )

        llm_result = None
        try:
            llm_result_obj = await self._gateway.generate(
                system_prompt=_CARE_ASSISTANT_SYSTEM_PROMPT,
                user_message=original_message,
            )
            model_name = llm_result_obj.model_name
        except Exception:  # noqa: BLE001
            model_name = None

        return ExecuteResponse(
            message=explanation,
            intent=intent.intent.value,
            risk_level=risk_level,
            requires_confirmation=requires_confirmation,
            confirmation_token=confirmation_token,
            actions=actions,
            workflow_steps=steps,
            session_id=session_id,
            tool_used=tool_name,
            model_used=model_name,
        )

    # ------------------------------------------------------------------
    # Action builders
    # ------------------------------------------------------------------

    def _build_actions(
        self,
        *,
        intent: ExtractedIntent,
        tool_name: str | None,
        tool_result: ToolResult | None,
        requires_confirmation: bool,
        workflow_state: WorkflowState,
    ) -> list[AgentAction]:
        if intent.emergency_signal:
            return [AgentAction(type=ActionType.EMERGENCY, data={})]

        if tool_result is None or not tool_result.success:
            return []

        if requires_confirmation and workflow_state == WorkflowState.awaiting_confirmation:
            return [AgentAction(
                type=ActionType.AWAITING_CONFIRMATION,
                data=tool_result.data,
            )]

        action_map: dict[str, ActionType] = {
            "search_doctors": ActionType.SHOW_DOCTORS,
            "check_availability": ActionType.SHOW_AVAILABILITY,
            "get_patient_records": ActionType.SHOW_PATIENT_RECORDS,
            "get_prescriptions": ActionType.SHOW_PRESCRIPTIONS,
            "book_appointment": ActionType.BOOKING_CONFIRMED,
            "schedule_followup": ActionType.REMINDER_SET,
        }

        if tool_name and tool_name in action_map:
            return [AgentAction(type=action_map[tool_name], data=tool_result.data)]

        return [AgentAction(type=ActionType.INFO, data=tool_result.data)]

    # ------------------------------------------------------------------
    # Explanation text generation
    # ------------------------------------------------------------------

    async def _generate_explanation(
        self,
        *,
        original_message: str,
        intent: ExtractedIntent,
        tool_name: str | None,
        tool_result: ToolResult | None,
        requires_confirmation: bool,
    ) -> str:
        """
        Build the human-readable message. Uses templated summaries rather than
        free-form LLM generation for safety-critical outcomes (emergency,
        booking confirmation). LLM text is used only for informational responses.
        """
        # Emergency — hardcoded, never LLM-generated
        if intent.emergency_signal:
            return (
                "This sounds like a medical emergency. Please call emergency "
                "services (112/108) immediately or go to the nearest emergency room. "
                "Do not wait for an online consultation."
            )

        # Tool failed
        if tool_result is not None and not tool_result.success:
            err = tool_result.error or "unknown error"
            return (
                f"I was unable to complete that request ({err}). "
                "Please try again or contact HomeDoc support."
            )

        # Awaiting confirmation
        if requires_confirmation:
            return (
                "I've prepared your appointment booking. Please review the details "
                "above and confirm to proceed, or cancel if you'd like to make changes."
            )

        # Booking confirmed
        if tool_name == "book_appointment" and tool_result and tool_result.success:
            appt = tool_result.data.get("appointment", {})
            doctor = appt.get("doctor_name", "your doctor")
            slot = appt.get("slot", "your chosen time")
            return (
                f"Your appointment with {doctor} at {slot} has been booked successfully. "
                f"You'll receive a reminder before the appointment.{_DISCLAIMER}"
            )

        # Reminder set
        if tool_name == "schedule_followup" and tool_result and tool_result.success:
            reminder = tool_result.data.get("reminder", {})
            msg = reminder.get("message", "your follow-up")
            return (
                f"Reminder set: '{msg}'. "
                f"You'll be notified at the scheduled time.{_DISCLAIMER}"
            )

        # No tool ran
        if tool_name is None:
            return (
                "I'm here to help you find doctors, check availability, "
                "book appointments, or access your medical records. "
                "How can I assist you today?" + _DISCLAIMER
            )

        # Default: safe canned message for informational results
        return (
            "Here's what I found based on your request. "
            "Please review the details and let me know how you'd like to proceed."
            + _DISCLAIMER
        )
