"""
Permission Manager — role-based and resource-level access control.

This runs BEFORE any tool call. It answers two questions:
1. Is this role allowed to call this tool at all?
2. Is this specific action on this specific resource permitted for this user?

Critical design rule: permission decisions are NEVER delegated to the LLM.
This is deterministic code that an LLM cannot talk its way past.

[INTEGRATION POINT: In production, extend check_resource_access() to query
 treating-relationship tables (doctor<->patient assignment) and consent
 records rather than using the simplified mock rules here.]
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class PermissionDecision:
    allowed: bool
    reason: str
    details: dict[str, Any] | None = None


# ---------------------------------------------------------------------------
# Tool-level role requirements (mirrors tool.allowed_roles but centralised
# here so the safety layer has a single source of truth)
# ---------------------------------------------------------------------------
_TOOL_ALLOWED_ROLES: dict[str, tuple[str, ...]] = {
    "search_doctors":       ("patient", "doctor", "admin"),
    "check_availability":   ("patient", "doctor", "admin"),
    "book_appointment":     ("patient", "admin"),
    "get_patient_records":  ("patient", "doctor", "admin"),
    "get_prescriptions":    ("patient", "doctor", "admin"),
    "schedule_followup":    ("patient", "doctor", "admin"),
}

# Tools that allow patients but restrict them to their OWN data only
_PATIENT_OWN_RECORD_TOOLS: frozenset[str] = frozenset({
    "get_patient_records",
    "get_prescriptions",
    "book_appointment",
    "schedule_followup",
})


class PermissionManager:
    """
    Evaluates whether a given (user_id, role, patient_id) combination is
    permitted to execute a given tool against a given resource.

    Designed for defence-in-depth: the ToolRegistry also checks roles,
    and individual tools also check patient_id ownership. This layer
    fires first and can short-circuit the entire pipeline.
    """

    def check_tool_access(
        self,
        *,
        role: str,
        tool_name: str,
        user_id: str,
        patient_id: str,
        arguments: dict[str, Any],
    ) -> PermissionDecision:
        """
        Combined role + resource-level access check.

        Returns PermissionDecision(allowed=True) if the call can proceed.
        Returns PermissionDecision(allowed=False, reason=...) if denied.
        """
        # 1. Is this tool in the allowlist at all?
        allowed_roles = _TOOL_ALLOWED_ROLES.get(tool_name)
        if allowed_roles is None:
            return PermissionDecision(
                allowed=False,
                reason="unknown_tool",
                details={"tool": tool_name},
            )

        # 2. Does the caller's role have access?
        if role not in allowed_roles:
            return PermissionDecision(
                allowed=False,
                reason="role_not_permitted",
                details={"role": role, "tool": tool_name, "allowed_roles": list(allowed_roles)},
            )

        # 3. Patient cross-record access check
        if role == "patient" and tool_name in _PATIENT_OWN_RECORD_TOOLS:
            requested_id = arguments.get("patient_id") or patient_id
            if requested_id != patient_id:
                return PermissionDecision(
                    allowed=False,
                    reason="cross_patient_access_denied",
                    details={
                        "requesting_patient_id": patient_id,
                        "requested_patient_id": requested_id,
                        "message": "Patients can only access their own records.",
                    },
                )

        # 4. Doctor role: allowed to access patient records in mock mode.
        # [INTEGRATION POINT: In production, verify the doctor has an active
        #  treating relationship with the patient before allowing access to
        #  patient-specific tools.]

        return PermissionDecision(allowed=True, reason="ok")
