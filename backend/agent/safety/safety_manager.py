"""
Safety Manager — healthcare-specific safety policy engine.

Sits between intent extraction and tool execution. Evaluates every
request against safety rules BEFORE any tool runs, and after every
tool result before the response is sent.

Critical design rules (all enforced in code, not prompt):
- Emergency signals hard-stop everything: no tool runs, no LLM detour.
- Sensitive operations always require explicit confirmation.
- Diagnosis/prescription requests are refused and redirected.
- Triage urgency results take priority over routine booking workflows.
- The LLM cannot override any of these decisions.

[INTEGRATION POINT: Pass existing symptom triage results and urgency
 classification from the existing triage system to evaluate_triage_priority()
 so high-urgency triage overrides any pending routine booking workflow.]
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from agent.schemas import AgentIntent, ExtractedIntent, RiskLevel

# ---------------------------------------------------------------------------
# Sensitive tools — always require explicit confirmation before execution.
# This list is hardcoded here; it cannot be modified via LLM output.
# ---------------------------------------------------------------------------
_SENSITIVE_TOOLS: frozenset[str] = frozenset({
    "book_appointment",
    "cancel_appointment",
    "reschedule_appointment",
})

_LOW_RISK_READ_ONLY_TOOLS: frozenset[str] = frozenset({
    "search_doctors",
    "check_availability",
})

_INFO_ONLY_TOOLS: frozenset[str] = frozenset({
    "get_patient_records",
    "get_prescriptions",
    "schedule_followup",
})

# Keywords indicating the user is asking for a diagnosis or prescription —
# both are outside the scope of this agent and must be refused.
_DIAGNOSIS_KEYWORDS: frozenset[str] = frozenset({
    "diagnose", "diagnosis", "what disease", "what condition",
    "what illness", "what is wrong with me",
})

_PRESCRIPTION_REQUEST_KEYWORDS: frozenset[str] = frozenset({
    "prescribe", "give me medicine", "what medicine", "what drug",
    "what tablet", "recommend medication",
})


@dataclass
class SafetyDecision:
    allowed: bool
    risk_level: RiskLevel
    requires_confirmation: bool
    reason: str
    details: dict[str, Any] = field(default_factory=dict)


class SafetyManager:
    """
    Healthcare AI safety policy engine.

    evaluate() must be called before EVERY tool execution. The result
    must be respected — an allowed=False result must immediately terminate
    the tool pipeline and return the appropriate response.
    """

    def evaluate(
        self,
        *,
        intent: ExtractedIntent,
        tool_name: str | None,
        message: str = "",
    ) -> SafetyDecision:
        """
        Evaluate whether the requested operation is safe to proceed.

        Call order matters: emergency check → diagnosis/prescription
        detection → sensitive tool check → low-risk check → default.
        """
        lower_message = message.lower()

        # ----------------------------------------------------------------
        # 1. Emergency — hard stop. No tool, no LLM explanation detour.
        #    Emergency detection is ALSO done at keyword level in
        #    IntentProcessor before this runs (defence in depth).
        # ----------------------------------------------------------------
        if intent.emergency_signal or intent.intent == AgentIntent.emergency:
            return SafetyDecision(
                allowed=False,
                risk_level=RiskLevel.escalation,
                requires_confirmation=True,
                reason="emergency_signal_detected",
                details={
                    "message": (
                        "Emergency detected. This agent has stopped all other "
                        "processing. Please seek immediate emergency care."
                    )
                },
            )

        # ----------------------------------------------------------------
        # 2. Diagnosis / prescription requests — refuse and redirect.
        #    The agent is never a substitute for clinical judgment.
        # ----------------------------------------------------------------
        if any(kw in lower_message for kw in _DIAGNOSIS_KEYWORDS):
            return SafetyDecision(
                allowed=False,
                risk_level=RiskLevel.sensitive,
                requires_confirmation=False,
                reason="diagnosis_request_refused",
                details={
                    "message": (
                        "This agent cannot provide diagnoses. Please consult "
                        "a licensed doctor through HomeDoc."
                    )
                },
            )

        if any(kw in lower_message for kw in _PRESCRIPTION_REQUEST_KEYWORDS):
            return SafetyDecision(
                allowed=False,
                risk_level=RiskLevel.sensitive,
                requires_confirmation=False,
                reason="prescription_request_refused",
                details={
                    "message": (
                        "This agent cannot prescribe medication. "
                        "Please speak with your doctor."
                    )
                },
            )

        # ----------------------------------------------------------------
        # 3. No tool selected — informational response, always safe
        # ----------------------------------------------------------------
        if tool_name is None:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                reason="no_tool_call",
            )

        # ----------------------------------------------------------------
        # 4. Sensitive tools — allowed but always require confirmation
        # ----------------------------------------------------------------
        if tool_name in _SENSITIVE_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.sensitive,
                requires_confirmation=True,
                reason="sensitive_tool_requires_confirmation",
                details={"tool": tool_name},
            )

        # ----------------------------------------------------------------
        # 5. Info-only tools — safe, no confirmation needed
        # ----------------------------------------------------------------
        if tool_name in _INFO_ONLY_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                reason="info_only_tool",
            )

        # ----------------------------------------------------------------
        # 6. Low-risk read-only tools — safe, no confirmation needed
        # ----------------------------------------------------------------
        if tool_name in _LOW_RISK_READ_ONLY_TOOLS:
            return SafetyDecision(
                allowed=True,
                risk_level=RiskLevel.low,
                requires_confirmation=False,
                reason="low_risk_read_only",
            )

        # ----------------------------------------------------------------
        # 7. Default: unknown/new tool — fail toward caution.
        #    Any tool added later without a safety classification gets
        #    treated as needing confirmation rather than silently allowed.
        # ----------------------------------------------------------------
        return SafetyDecision(
            allowed=True,
            risk_level=RiskLevel.confirm,
            requires_confirmation=True,
            reason="unclassified_tool_default_confirm",
            details={"tool": tool_name},
        )

    def evaluate_triage_priority(
        self,
        *,
        triage_urgency: str,
        pending_intent: AgentIntent,
    ) -> SafetyDecision | None:
        """
        Check whether a triage result should override a pending booking workflow.

        Returns a SafetyDecision that should replace the current workflow
        state if the triage result is high-urgency, or None if the
        current workflow can continue.

        [INTEGRATION POINT: Pass existing triage results and urgency
         classification from the existing symptom triage system here.
         The triage urgency levels should match the existing triage
         system's classification (e.g. "critical", "high", "moderate",
         "low").]
        """
        HIGH_URGENCY_LEVELS = {"critical", "high", "emergency"}

        if triage_urgency.lower() in HIGH_URGENCY_LEVELS:
            return SafetyDecision(
                allowed=False,
                risk_level=RiskLevel.escalation,
                requires_confirmation=True,
                reason="triage_urgency_overrides_routine_workflow",
                details={
                    "triage_urgency": triage_urgency,
                    "suppressed_intent": pending_intent.value,
                    "message": (
                        "Your symptoms indicate you may need urgent care. "
                        "Please seek immediate medical attention rather than "
                        "waiting for a routine appointment."
                    ),
                },
            )
        return None
