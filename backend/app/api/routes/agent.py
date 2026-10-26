"""
POST /ai/agent — replaces (conceptually) the earlier /ai/triage contract
from Day 3's AI Care feature with the real Day 3.2 agent architecture.
See backend/README.md "Relationship to the earlier /ai/triage contract"
for how the Flutter client should migrate.
"""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.ai.agent.memory import InMemorySessionStore
from app.ai.agent.orchestrator import AgentOrchestrator
from app.ai.gateway.gateway import AIGateway
from app.ai.safety.policy import SafetyEngine
from app.ai.tools.registry import ToolRegistry
from app.api.deps import get_current_user, get_db
from app.core.security import DecodedToken
from app.schemas.agent import AgentRequest, AgentResponse

router = APIRouter(prefix="/ai", tags=["ai-agent"])

# Process-lifetime singletons — cheap, stateless-except-for-memory-store
# objects. Recreating an AIGateway per-request would be wasteful; the
# session store intentionally IS shared/mutable state (Day 3.2 §22).
_gateway = AIGateway()
_tool_registry = ToolRegistry()
_safety_engine = SafetyEngine()
_session_store = InMemorySessionStore()
_orchestrator = AgentOrchestrator(
    gateway=_gateway,
    tool_registry=_tool_registry,
    safety_engine=_safety_engine,
    session_store=_session_store,
)


@router.post("/agent", response_model=AgentResponse)
async def run_agent(
    body: AgentRequest,
    db: Session = Depends(get_db),
    user: DecodedToken = Depends(get_current_user),
) -> AgentResponse:
    session_id = body.session_id or str(uuid.uuid4())
    return await _orchestrator.handle(
        message=body.message,
        session_id=session_id,
        user_id=user.user_id,
        role=user.role,
        db_session=db,
    )
