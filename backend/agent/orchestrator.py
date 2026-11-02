"""
Care Coordination Agent Orchestrator.

Controls the full workflow from patient message to structured response:

    Patient message
        → IntentProcessor (Gemini Flash / keyword fallback)
        → SafetyManager.evaluate() — emergency / diagnosis check
        → PermissionManager.check_tool_access()
        → ToolRegistry.execute()
        → (if requires_confirmation) → issue token, pend workflow
        → ResponseGenerator.build()
        → ExecuteResponse

Multi-step workflow support:
- Doctor search → availability → booking is a natural multi-step flow.
- After search_doctors, the session stores the found doctors.
- The patient selects a doctor and asks for availability → check_availability.
- Patient picks a slot → book_appointment (pending confirmation).
- Patient confirms → /agent/confirm re-executes book_appointment with confirmed=True.

Session state is stored in InMemoryWorkflowStore. In production this
should be a shared Redis store (see Architecture v1's real-time layer).

Design rules:
- Tool selection is a deterministic code mapping, not an LLM decision.
  The LLM suggests an intent; THIS CODE decides which tool runs.
- LLM output is never treated as proof that an operation succeeded.
- Safety checks run BEFORE and AFTER tool execution.

[INTEGRATION POINT: Pass existing Gemini Flash chatbot output to
 IntentProcessor.extract() to avoid double-calling Gemini for sessions
 where the chatbot has already classified intent.]

[INTEGRATION POINT: Expose agent endpoints for integration with the
 existing Flutter application via the router in agent/router.py.]
"""
from __future__ import annotations

import secrets
import uuid
from dataclasses import dataclass, field
from typing import Any

from app.core.logging import get_logger

from agent.intent_processor import IntentProcessor
from agent.repositories.mock_repository import (
    get_appointment_repository,
    get_doctor_repository,
    get_patient_repository,
    get_reminder_repository,
)
from agent.response_generator import ResponseGenerator
from agent.safety.permission_manager import PermissionManager
from agent.safety.safety_manager import SafetyDecision, SafetyManager
from agent.schemas import (
    AgentIntent,
    AgentStep,
    ExecuteRequest,
    ExecuteResponse,
    ExtractedIntent,
    RiskLevel,
    ToolResult,
    WorkflowState,
)
from agent.services.appointment_service import AppointmentService
from agent.services.doctor_service import DoctorService
from agent.services.patient_service import PatientService
from agent.tools.registry import ToolRegistry

logger = get_logger("homedoc.agent.orchestrator")

# ---------------------------------------------------------------------------
# Tool selection map — intent → tool name.
# The LLM provides the intent; THIS MAP decides the tool.
# Hallucinated tool names from the LLM cannot appear here.
# ---------------------------------------------------------------------------
_INTENT_TO_TOOL: dict[AgentIntent, str] = {
    AgentIntent.doctor_search: "search_doctors",
    AgentIntent.check_availability: "check_availability",
    AgentIntent.book_appointment: "book_appointment",
    AgentIntent.get_patient_records: "get_patient_records",
    AgentIntent.get_prescriptions: "get_prescriptions",
    AgentIntent.schedule_followup: "schedule_followup",
}


# ---------------------------------------------------------------------------
# Per-session workflow state
# ---------------------------------------------------------------------------

@dataclass
class PendingConfirmation:
    """Details of an action awaiting explicit patient confirmation."""
    token: str
    tool_name: str
    arguments: dict[str, Any]
    intent: ExtractedIntent


@dataclass
class WorkflowSession:
    session_id: str
    state: WorkflowState = WorkflowState.idle
    last_intent: ExtractedIntent | None = None
    pending_confirmation: PendingConfirmation | None = None
    last_doctors: list[dict[str, Any]] = field(default_factory=list)
    last_availability: list[dict[str, Any]] = field(default_factory=list)
    steps: list[AgentStep] = field(default_factory=list)
    step_counter: int = 0

    def add_step(self, *, tool_used: str | None, intent: str, success: bool, summary: str) -> AgentStep:
        self.step_counter += 1
        step = AgentStep(
            step_index=self.step_counter,
            tool_used=tool_used,
            intent=intent,
            success=success,
            summary=summary,
        )
        self.steps.append(step)
        return step


class InMemoryWorkflowStore:
    """Process-lifetime in-memory session store.

    For production: replace with Redis to share state across backend
    instances and survive restarts (Architecture v1 real-time layer).
    """

    def __init__(self) -> None:
        self._sessions: dict[str, WorkflowSession] = {}

    def get_or_create(self, session_id: str) -> WorkflowSession:
        if session_id not in self._sessions:
            self._sessions[session_id] = WorkflowSession(session_id=session_id)
        return self._sessions[session_id]

    def get(self, session_id: str) -> WorkflowSession | None:
        return self._sessions.get(session_id)


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------

class CareCoordinationOrchestrator:
    """
    Main orchestrator. One instance per application (singleton).
    Session state is isolated per session_id inside workflow_store.
    """

    def __init__(
        self,
        *,
        intent_processor: IntentProcessor,
        tool_registry: ToolRegistry,
        safety_manager: SafetyManager,
        permission_manager: PermissionManager,
        response_generator: ResponseGenerator,
        workflow_store: InMemoryWorkflowStore,
    ) -> None:
        self._intent = intent_processor
        self._tools = tool_registry
        self._safety = safety_manager
        self._permissions = permission_manager
        self._response_gen = response_generator
        self._sessions = workflow_store

    # ------------------------------------------------------------------
    # Public entry points
    # ------------------------------------------------------------------

    async def handle_execute(self, *, request: ExecuteRequest) -> ExecuteResponse:
        """
        Handle a new patient message (POST /agent/execute).

        Full pipeline: intent → safety → permissions → tool → response.
        """
        session_id = request.session_id or str(uuid.uuid4())
        session = self._sessions.get_or_create(session_id)

        logger.info("agent_execute_start session_id=%s patient_id=%s message_length=%d", session_id, request.patient_id, len(request.message))

        # Step 1: Extract intent
        intent = await self._intent.extract(message=request.message)

        logger.info("agent_intent_extracted intent=%s confidence=%.2f emergency=%s entities=%s", intent.intent.value, intent.confidence, intent.emergency_signal, list(intent.entities.keys()))

        # Step 2: Safety check — BEFORE tool selection or execution
        tool_name = _INTENT_TO_TOOL.get(intent.intent)
        safety_decision = self._safety.evaluate(
            intent=intent,
            tool_name=tool_name,
            message=request.message,
        )

        if not safety_decision.allowed:
            step = session.add_step(
                tool_used=None,
                intent=intent.intent.value,
                success=False,
                summary=f"Safety gate: {safety_decision.reason}",
            )
            return await self._build_safety_blocked_response(
                request=request,
                intent=intent,
                safety_decision=safety_decision,
                session=session,
                session_id=session_id,
                steps=[step],
            )

        # Step 3: Permission check
        perm_decision = self._permissions.check_tool_access(
            role="patient",   # default; production derives from JWT
            tool_name=tool_name or "__none__",
            user_id=request.patient_id,
            patient_id=request.patient_id,
            arguments=intent.entities,
        )

        if tool_name and not perm_decision.allowed:
            step = session.add_step(
                tool_used=None,
                intent=intent.intent.value,
                success=False,
                summary=f"Permission denied: {perm_decision.reason}",
            )
            return ExecuteResponse(
                message=f"You do not have permission to perform this action. ({perm_decision.reason})",
                intent=intent.intent.value,
                risk_level=RiskLevel.sensitive,
                requires_confirmation=False,
                session_id=session_id,
                actions=[],
                workflow_steps=list(session.steps),
            )

        # Step 4: Build tool arguments (merge entities + session context)
        arguments = self._build_arguments(
            intent=intent,
            request=request,
            session=session,
        )

        # Step 5: Confirmation gate for sensitive tools
        if safety_decision.requires_confirmation:
            token = secrets.token_urlsafe(16)
            session.pending_confirmation = PendingConfirmation(
                token=token,
                tool_name=tool_name,
                arguments={**arguments, "confirmed": False},
                intent=intent,
            )
            session.state = WorkflowState.awaiting_confirmation

            step = session.add_step(
                tool_used=tool_name,
                intent=intent.intent.value,
                success=True,
                summary="Awaiting patient confirmation before executing.",
            )

            from agent.schemas import ActionType, AgentAction
            return ExecuteResponse(
                message=(
                    "I've prepared your request. Please review the details and "
                    "confirm to proceed."
                ),
                intent=intent.intent.value,
                risk_level=safety_decision.risk_level,
                requires_confirmation=True,
                confirmation_token=token,
                actions=[AgentAction(
                    type=ActionType.AWAITING_CONFIRMATION,
                    data={
                        "tool": tool_name,
                        "preview": arguments,
                        "instructions": "Send confirmation_token with confirmed=true to /agent/confirm",
                    },
                )],
                workflow_steps=list(session.steps),
                session_id=session_id,
                tool_used=tool_name,
            )

        # Step 6: Execute tool (no confirmation needed)
        tool_result: ToolResult | None = None
        if tool_name:
            from agent.tools.base import ToolCallContext
            context = ToolCallContext(
                user_id=request.patient_id,
                role="patient",
                patient_id=request.patient_id,
            )
            raw_result = await self._tools.execute(
                tool_name=tool_name,
                context=context,
                arguments=arguments,
            )
            tool_result = ToolResult(
                success=raw_result.success,
                data=raw_result.data,
                error=raw_result.error,
            )

            # Store useful results in session for multi-step continuity
            self._update_session_context(
                session=session,
                tool_name=tool_name,
                tool_result=tool_result,
            )

        step = session.add_step(
            tool_used=tool_name,
            intent=intent.intent.value,
            success=tool_result.success if tool_result else True,
            summary=(
                tool_result.error
                if tool_result and not tool_result.success
                else f"Tool '{tool_name}' executed successfully"
                if tool_name
                else "Informational response"
            ),
        )
        session.last_intent = intent

        # Step 7: Build response
        response = await self._response_gen.build(
            original_message=request.message,
            intent=intent,
            tool_name=tool_name,
            tool_result=tool_result,
            risk_level=safety_decision.risk_level,
            requires_confirmation=False,
            confirmation_token=None,
            session_id=session_id,
            steps=list(session.steps),
            workflow_state=session.state,
        )

        logger.info("agent_execute_complete session_id=%s intent=%s tool_used=%s success=%s", session_id, intent.intent.value, tool_name, tool_result.success if tool_result else True)

        return response

    async def handle_confirm(
        self,
        *,
        session_id: str,
        confirmation_token: str,
        confirmed: bool,
    ) -> ExecuteResponse:
        """
        Handle explicit confirmation for a pending action (POST /agent/confirm).

        Validates the confirmation token, then re-executes the pending tool
        with confirmed=True (or cancels if confirmed=False).
        """
        session = self._sessions.get(session_id)

        if not session or not session.pending_confirmation:
            return ExecuteResponse(
                message="No pending action found for this session. Please start a new request.",
                intent="unknown",
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                session_id=session_id,
                actions=[],
                workflow_steps=[],
            )

        pending = session.pending_confirmation

        # Constant-time token comparison to prevent timing attacks
        if not secrets.compare_digest(pending.token, confirmation_token):
            step = session.add_step(
                tool_used=None,
                intent="confirm",
                success=False,
                summary="Invalid confirmation token supplied.",
            )
            return ExecuteResponse(
                message="Invalid confirmation token. Please retry the original request.",
                intent="confirm",
                risk_level=RiskLevel.sensitive,
                requires_confirmation=False,
                session_id=session_id,
                actions=[],
                workflow_steps=list(session.steps),
            )

        # Patient cancelled
        if not confirmed:
            session.pending_confirmation = None
            session.state = WorkflowState.idle
            step = session.add_step(
                tool_used=None,
                intent="confirm",
                success=True,
                summary="Patient cancelled the pending action.",
            )
            return ExecuteResponse(
                message="Action cancelled. Let me know if you'd like to try something else.",
                intent="confirm",
                risk_level=RiskLevel.info,
                requires_confirmation=False,
                session_id=session_id,
                actions=[],
                workflow_steps=list(session.steps),
            )

        # Patient confirmed — execute with confirmed=True
        tool_name = pending.tool_name
        arguments = {**pending.arguments, "confirmed": True}
        intent = pending.intent

        from agent.tools.base import ToolCallContext
        context = ToolCallContext(
            user_id=session_id,  # session_id used as proxy user_id here
            role="patient",
            patient_id=arguments.get("patient_id", session_id),
        )

        raw_result = await self._tools.execute(
            tool_name=tool_name,
            context=context,
            arguments=arguments,
        )
        tool_result = ToolResult(
            success=raw_result.success,
            data=raw_result.data,
            error=raw_result.error,
        )

        # Clear pending state only if booking succeeded
        if tool_result.success:
            session.pending_confirmation = None
            session.state = WorkflowState.completed
        else:
            # Leave pending so the patient can retry
        logger.warning("agent_confirm_tool_failed session_id=%s tool=%s error=%s", session_id, tool_name, tool_result.error)

        step = session.add_step(
            tool_used=tool_name,
            intent="confirm",
            success=tool_result.success,
            summary=(
                f"Confirmed execution of '{tool_name}': "
                + (tool_result.error or "success")
            ),
        )

        response = await self._response_gen.build(
            original_message=f"[confirmed: {tool_name}]",
            intent=intent,
            tool_name=tool_name,
            tool_result=tool_result,
            risk_level=RiskLevel.sensitive,
            requires_confirmation=False,
            confirmation_token=None,
            session_id=session_id,
            steps=list(session.steps),
            workflow_state=session.state,
        )
        return response

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _build_arguments(
        self,
        *,
        intent: ExtractedIntent,
        request: ExecuteRequest,
        session: WorkflowSession,
    ) -> dict[str, Any]:
        """
        Merge intent entities with session context and request metadata.

        Session context is used to carry forward state from previous steps
        (e.g. the doctor_id selected in step 1 is available in step 2).
        """
        args: dict[str, Any] = dict(intent.entities)

        # Always inject patient_id from the authenticated request context,
        # never from the LLM-extracted entities alone.
        args["patient_id"] = request.patient_id

        # If the patient said "check availability" but didn't specify a
        # doctor, use the first doctor from the last search results.
        if (
            intent.intent == AgentIntent.check_availability
            and not args.get("doctor_id")
            and session.last_doctors
        ):
            args["doctor_id"] = session.last_doctors[0]["id"]
            logger.info(
                "agent_context_carry_forward",
                field="doctor_id",
                value=args["doctor_id"],
            )

        # If booking without a slot, carry forward first available slot
        if (
            intent.intent == AgentIntent.book_appointment
            and not args.get("slot")
            and session.last_availability
        ):
            first_slot = session.last_availability[0]
            args["slot"] = first_slot.get("slot")
            args["doctor_id"] = args.get("doctor_id") or first_slot.get("doctor_id")
            args["date"] = args.get("date") or first_slot.get("date")
            logger.info(
                "agent_context_carry_forward",
                field="slot",
                value=args["slot"],
            )

        return args

    def _update_session_context(
        self,
        *,
        session: WorkflowSession,
        tool_name: str,
        tool_result: ToolResult,
    ) -> None:
        """Store tool results in session for multi-step continuity."""
        if not tool_result.success:
            return

        if tool_name == "search_doctors":
            session.last_doctors = tool_result.data.get("doctors", [])
            session.state = WorkflowState.awaiting_selection

        elif tool_name == "check_availability":
            session.last_availability = tool_result.data.get("available_slots", [])

    async def _build_safety_blocked_response(
        self,
        *,
        request: ExecuteRequest,
        intent: ExtractedIntent,
        safety_decision: SafetyDecision,
        session: WorkflowSession,
        session_id: str,
        steps: list[AgentStep],
    ) -> ExecuteResponse:
        """Build the response for a safety-blocked request."""
        from agent.schemas import ActionType, AgentAction

        if intent.emergency_signal or intent.intent == AgentIntent.emergency:
            actions = [AgentAction(type=ActionType.EMERGENCY, data={})]
            message = (
                "This sounds like a medical emergency. Please call emergency "
                "services (112 / 108) immediately. Do not wait."
            )
        else:
            actions = []
            message = safety_decision.details.get(
                "message",
                "This request cannot be processed for safety reasons.",
            )

        return ExecuteResponse(
            message=message,
            intent=intent.intent.value,
            risk_level=safety_decision.risk_level,
            requires_confirmation=safety_decision.requires_confirmation,
            actions=actions,
            workflow_steps=steps,
            session_id=session_id,
            tool_used=None,
        )


# ---------------------------------------------------------------------------
# Default singleton factory — used by the router
# ---------------------------------------------------------------------------

def build_default_orchestrator() -> CareCoordinationOrchestrator:
    """
    Build the orchestrator with all default (mock) dependencies.

    Tests override individual components by constructing the orchestrator
    directly.
    """
    from app.ai.gateway.gateway import AIGateway

    gateway = AIGateway()  # uses Gemini if GEMINI_API_KEY set, else Mock

    doctor_service = DoctorService(repo=get_doctor_repository())
    appointment_service = AppointmentService(repo=get_appointment_repository())
    patient_service = PatientService(
        patient_repo=get_patient_repository(),
        reminder_repo=get_reminder_repository(),
    )
    tool_registry = ToolRegistry(
        doctor_service=doctor_service,
        appointment_service=appointment_service,
        patient_service=patient_service,
    )

    return CareCoordinationOrchestrator(
        intent_processor=IntentProcessor(gateway=gateway),
        tool_registry=tool_registry,
        safety_manager=SafetyManager(),
        permission_manager=PermissionManager(),
        response_generator=ResponseGenerator(gateway=gateway),
        workflow_store=InMemoryWorkflowStore(),
    )
