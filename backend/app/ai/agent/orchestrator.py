"""
HomeDoc Care Coordination Agent — the orchestrator (Day 3.2 §13).

Implements exactly the pipeline from the prompt:
    User -> Intent Detection -> Context Retrieval -> Reasoning ->
    Tool Selection -> Safety/Policy Check -> Tool Execution -> Result ->
    LLM Explanation -> Confirmation if required

Only ONE flow is fully wired end-to-end (Day 3.2 §26): free-text ->
doctor search -> SHOW_DOCTORS action. Everything else in `_select_tool`
either isn't reached (no intent maps to it yet) or would hit
GetPatientProfileTool's honest "not_implemented" response — nothing here
pretends a workflow exists that doesn't.
"""
from __future__ import annotations

from app.ai.agent.intents import IntentExtraction
from app.ai.agent.memory import InMemorySessionStore
from app.ai.gateway.gateway import AIGateway
from app.ai.safety.policy import SafetyEngine
from app.ai.tools.base import ToolContext
from app.ai.tools.registry import ToolRegistry
from app.core.logging import log_ai_event
from app.core.security import UserRole
from app.schemas.agent import ActionType, AgentAction, AgentResponse, RiskLevel

_CARE_ASSISTANT_SYSTEM_PROMPT = (
    "You are HomeDoc's care coordination assistant. You help patients find "
    "doctors and navigate care. You are NOT a doctor: never diagnose, "
    "never recommend medication, never claim certainty about a medical "
    "condition. Keep responses short and plain-language."
)


class AgentOrchestrator:
    def __init__(
        self,
        *,
        gateway: AIGateway,
        tool_registry: ToolRegistry,
        safety_engine: SafetyEngine,
        session_store: InMemorySessionStore,
    ):
        self._gateway = gateway
        self._tools = tool_registry
        self._safety = safety_engine
        self._sessions = session_store

    async def handle(
        self, *, message: str, session_id: str, user_id: str, role: UserRole, db_session
    ) -> AgentResponse:
        conversation = self._sessions.get_conversation(session_id)
        conversation.add(role="user", content="[symptom/message text — not persisted verbatim in logs]")
        # NOTE: the literal message IS kept in-memory in `conversation` for
        # this session (needed for multi-turn context later) but is NEVER
        # passed to log_ai_event — see core/logging.py's redaction list,
        # which also blocks it if a future call site forgets.

        log_ai_event("agent_request_received", session_id=session_id, user_id=user_id, role=role.value)

        # 1. Intent Detection
        intent = await self._gateway.extract_intent(user_message=message)

        # 2. Context Retrieval — foundation stage: session facts only.
        #    RAG/long-term context intentionally not wired in (app/ai/rag
        #    is unimplemented — see its module docstring).
        session_memory = self._sessions.get_session(session_id)
        if "specialty" in intent.entities:
            session_memory.facts["specialty"] = intent.entities["specialty"]

        # 3. Reasoning / 4. Tool Selection
        tool_name = self._select_tool(intent)

        # 5. Safety / Policy Check — BEFORE any tool executes, always.
        decision = self._safety.evaluate(intent=intent, tool_name=tool_name)

        if not decision.allowed:
            # Emergency path: stop, do not call a tool, do not continue
            # reasoning about the original request (Day 3.2 §24).
            log_ai_event("agent_emergency_escalation", session_id=session_id, user_id=user_id)
            return AgentResponse(
                message=(
                    "This may be a medical emergency. Please seek immediate "
                    "emergency care or use HomeDoc's emergency request now."
                ),
                intent=intent.intent,
                risk_level=RiskLevel.escalation,
                requires_confirmation=True,
                actions=[AgentAction(type=ActionType.EMERGENCY, data={})],
                session_id=session_id,
                tool_used=None,
                model_used=None,
            )

        # 6. Tool Execution
        actions: list[AgentAction] = []
        tool_used: str | None = None
        if tool_name is not None:
            context = ToolContext(user_id=user_id, role=role, db_session=db_session)
            result = await self._tools.execute(tool_name=tool_name, context=context, arguments=intent.entities)
            tool_used = tool_name
            actions = self._actions_from_tool_result(tool_name=tool_name, success=result.success, data=result.data)

        # 7. LLM Explanation
        explanation = await self._gateway.generate(
            system_prompt=_CARE_ASSISTANT_SYSTEM_PROMPT, user_message=message
        )
        conversation.add(role="assistant", content="[response text — see actions for structured result]")

        response = AgentResponse(
            message=explanation.text,
            intent=intent.intent,
            risk_level=decision.risk_level,
            requires_confirmation=decision.requires_confirmation,
            actions=actions,
            session_id=session_id,
            tool_used=tool_used,
            model_used=explanation.model_name,
        )

        log_ai_event(
            "agent_response_ready",
            session_id=session_id,
            intent=intent.intent,
            tool_used=tool_used,
            risk_level=decision.risk_level.value,
            requires_confirmation=decision.requires_confirmation,
        )
        return response

    def _select_tool(self, intent: IntentExtraction) -> str | None:
        # Deliberately a tiny, explicit mapping — NOT an LLM-driven
        # decision (Day 3.2 §15: the LLM suggests, code decides). Extend
        # this as more intents/tools are wired up; a hallucinated tool
        # name from the LLM has no path into this function at all.
        if intent.intent == "doctor_search":
            return "search_doctors"
        return None

    def _actions_from_tool_result(
        self, *, tool_name: str, success: bool, data: dict
    ) -> list[AgentAction]:
        if tool_name == "search_doctors" and success:
            return [AgentAction(type=ActionType.SHOW_DOCTORS, data=data)]
        return []
