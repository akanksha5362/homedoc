"""
Patient tools: get_patient_records and get_prescriptions.

Access control rules:
- Patients can ONLY access their OWN records (patient_id == user_id).
- Doctors can access records of patients they are treating (mock: any).
- Admins have full access.

These checks are enforced in BOTH the PermissionManager (before tool call)
AND inside the tool itself (defence in depth). A patient who provides
someone else's patient_id gets a permission error, not the other patient's
data.

[INTEGRATION POINT: Connect patient and prescription tools to authenticated
 backend services with proper consent gates and field-level encryption.]
"""
from __future__ import annotations

from typing import Any

from agent.services.patient_service import PatientService
from agent.tools.base import AgentTool, ToolCallContext, ToolResult


class GetPatientRecordsTool(AgentTool):
    """
    Retrieve authorized patient information and medical history.

    Patients can only view their own records. Doctors and admins can
    view any patient's records (mock; in production this would be
    constrained to treating relationships).

    [INTEGRATION POINT: Connect to authenticated backend patient services.
     Verify consent status before returning any health data.]
    """
    name = "get_patient_records"
    description = (
        "Retrieve a patient's medical history and profile. "
        "Patients can only access their own records."
    )
    allowed_roles = ("patient", "doctor", "admin")

    def __init__(self, patient_service: PatientService) -> None:
        self._service = patient_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        # Determine which patient's records are being requested
        requested_patient_id = arguments.get("patient_id") or context.patient_id

        # Defence-in-depth: enforce patient can only see own records.
        # PermissionManager also checks this before we get here.
        if context.role == "patient" and requested_patient_id != context.patient_id:
            return ToolResult(
                success=False,
                error="permission_denied",
                data={
                    "message": (
                        "You are not authorized to access another patient's records."
                    )
                },
            )

        records = self._service.get_records(patient_id=requested_patient_id)

        if records is None:
            return ToolResult(
                success=False,
                error="not_found",
                data={"message": f"No records found for patient {requested_patient_id}."},
            )

        return ToolResult(
            success=True,
            data={"patient_records": records},
        )


class GetPrescriptionsTool(AgentTool):
    """
    Retrieve existing prescriptions for the authenticated patient.

    [INTEGRATION POINT: Connect to authenticated backend prescription service.
     Filter by consent and ownership before returning medication data.]
    """
    name = "get_prescriptions"
    description = (
        "Retrieve current and historical prescriptions for the authenticated patient. "
        "Patients can only access their own prescriptions."
    )
    allowed_roles = ("patient", "doctor", "admin")

    def __init__(self, patient_service: PatientService) -> None:
        self._service = patient_service

    async def execute(
        self, *, context: ToolCallContext, arguments: dict[str, Any]
    ) -> ToolResult:
        requested_patient_id = arguments.get("patient_id") or context.patient_id

        # Defence-in-depth cross-patient access check
        if context.role == "patient" and requested_patient_id != context.patient_id:
            return ToolResult(
                success=False,
                error="permission_denied",
                data={
                    "message": (
                        "You are not authorized to access another patient's prescriptions."
                    )
                },
            )

        prescriptions = self._service.get_prescriptions(
            patient_id=requested_patient_id
        )

        return ToolResult(
            success=True,
            data={
                "prescriptions": prescriptions,
                "count": len(prescriptions),
            },
        )
