"""
Healthcare AI Safety & Policy Engine (Day 3.2 §23). Sits between the
orchestrator's reasoning step and tool execution. Critical rule: this is
CODE, not a system-prompt instruction — an LLM cannot talk its way past
it (Day 3.2 §23: "Do NOT rely only on the system prompt").
"""
from __future__ import annotations

from dataclasses import dataclass

from app.ai.agent.intents import IntentExtraction
from app.schemas.agent import RiskLevel

# Tools considered high-risk enough to always require explicit
# confirmation, regardless of what the LLM/orchestrator decided upstream.
# This list is deliberately hardcoded here, not derived from LLM output.
_SENSITIVE_TOOLS = {"book_appointment", "initiate_payment", "cancel_appointment", "reschedule_appointment"}

_INFO_ONLY_TOOLS = {"get_appointment", "get_prescriptions", "get_doctor_eta"}

# Day 3.2 §16 Level 1 example is literally "Show me available doctors" —
# these tools are read-only, non-personal (no patient-specific data
# exposed), and safe to run without confirmation.
_LOW_RISK_TOOLS = {"search_doctors", "get_doctor_profile", "get_doctor_availability"}


@dataclass
class SafetyDecision:
    allowed: bool
    risk_level: RiskLevel
    requires_confirmation: bool
    reason: str


class SafetyEngine:
    def evaluate(self, *, intent: IntentExtraction, tool_name: str | None) -> SafetyDecision:
        # Emergency signal overrides everything else, unconditionally —
        # no tool call, no LLM explanation detour. This is the fail-safe
        # floor described in Day 3.2 §16 Level 4 / §24.
        if intent.emergency_signal:
            return SafetyDecision(
                allowed=False,
                risk_level=RiskLevel.escalation,
                requires_confirmation=True,
                reason="emergency_signal_detected",
            )

        if tool_name is None:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                reason="no_tool_call",
            )

        if tool_name in _SENSITIVE_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.sensitive,
                requires_confirmation=True,
                reason="sensitive_tool",
            )

        if tool_name in _INFO_ONLY_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                reason="info_only_tool",
            )

        if tool_name in _LOW_RISK_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.low,
                requires_confirmation=False,
                reason="low_risk_read_only_tool",
            )

        # Default posture for any tool not explicitly classified above:
        # treat as needing confirmation rather than silently allowing it.
        # Fail toward caution for tools this engine doesn't yet know about
        # (e.g. new tools added later without updating this policy).
        return SafetyDecision(
            allowed=True,
            risk_level=RiskLevel.confirm,
            requires_confirmation=True,
            reason="unclassified_tool_default_confirm",
        )
