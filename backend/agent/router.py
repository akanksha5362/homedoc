"""
Standalone FastAPI router for the Care Coordination Agent.

Endpoints:
    GET  /agent/health   — liveness + registered tools list
    POST /agent/execute  — process a patient message
    POST /agent/confirm  — complete a pending confirmation

This router is independent of the existing /ai/agent route
(app/api/routes/agent.py). It can be:
  - Mounted on the existing FastAPI app in backend/app/main.py
  - Run as its own standalone ASGI app for isolated testing

[INTEGRATION POINT: Mount this router on the existing FastAPI app by
 adding `app.include_router(agent_router)` in app/main.py once you're
 ready to integrate with the existing application.]

[INTEGRATION POINT: Expose these endpoints for integration with the
 existing Flutter application. The Flutter client should call
 POST /agent/execute with the patient's message and use the
 confirmation_token from the response to call POST /agent/confirm.]

Authentication note: For standalone testing, patient_id is passed in the
request body. In production integration, derive it from the JWT token
via app/api/deps.py:get_current_user and remove it from the request body.

[INTEGRATION POINT: Replace the patient_id field in ExecuteRequest with
 a Depends(get_current_user) call from app/api/deps.py for production
 auth integration.]
"""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from app.core.config import settings
from app.core.logging import get_logger

from agent.orchestrator import CareCoordinationOrchestrator, build_default_orchestrator
from agent.schemas import ConfirmRequest, ExecuteRequest, ExecuteResponse, HealthResponse

logger = get_logger("homedoc.agent.router")

router = APIRouter(prefix="/agent", tags=["care-coordination-agent"])

# Process-lifetime singleton orchestrator.
# Tests replace this by constructing their own orchestrator.
_orchestrator: CareCoordinationOrchestrator = build_default_orchestrator()


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    """
    Agent health check and capabilities overview.

    Returns the list of registered tools and whether the agent is running
    in mock mode (no Gemini API key) or real mode.
    """
    registered_tools = _orchestrator._tools.list_names()
    return HealthResponse(
        status="ok",
        version="1.0.0-standalone",
        mock_mode=not settings.uses_real_llm,
        registered_tools=registered_tools,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@router.post("/execute", response_model=ExecuteResponse)
async def execute(body: ExecuteRequest) -> ExecuteResponse:
    """
    Process a patient message through the full agent pipeline.

    The agent will:
    1. Extract intent and entities from the message.
    2. Run safety and permission checks.
    3. Execute the appropriate tool (or return a confirmation request
       for sensitive actions like booking).
    4. Return a structured response with actions for the Flutter client.

    If `requires_confirmation` is True in the response, the client must
    send the `confirmation_token` to POST /agent/confirm to complete the
    action.
    """
    logger.info(
        "agent_route_execute",
        patient_id=body.patient_id,
        message_length=len(body.message),
    )
    try:
        return await _orchestrator.handle_execute(request=body)
    except Exception as exc:
        logger.error(
            "agent_route_execute_error",
            error_type=type(exc).__name__,
            error=str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Care coordination is temporarily unavailable. Please try again.",
        ) from exc


@router.post("/confirm", response_model=ExecuteResponse)
async def confirm(body: ConfirmRequest) -> ExecuteResponse:
    """
    Complete a pending confirmation (e.g. confirm an appointment booking).

    Send `confirmed: true` to proceed with the action, or `confirmed: false`
    to cancel it. The `confirmation_token` must match the token returned
    by the previous /agent/execute call.

    Invalid or expired tokens will return a 400 response.
    """
    logger.info(
        "agent_route_confirm",
        session_id=body.session_id,
        confirmed=body.confirmed,
    )
    try:
        return await _orchestrator.handle_confirm(
            session_id=body.session_id,
            confirmation_token=body.confirmation_token,
            confirmed=body.confirmed,
        )
    except Exception as exc:
        logger.error(
            "agent_route_confirm_error",
            session_id=body.session_id,
            error_type=type(exc).__name__,
            error=str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to process confirmation. Please try again.",
        ) from exc
