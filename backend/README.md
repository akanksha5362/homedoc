# HomeDoc AI — Backend (Day 3.2 foundation)

FastAPI backend implementing the AI/ML/LLM/Agent architecture from Day 3.2,
on top of the auth/RBAC/database foundation it needs to run safely.

**Verification status: this backend was actually run in the authoring
sandbox** (Python + pip access were available, unlike the Flutter side).
`pytest` (18/18 passing), a live `uvicorn` server, and real `curl` requests
through the full register → auth → agent pipeline were all exercised for
real — see "What was actually verified" below. This is a meaningfully
different (stronger) verification status than the Flutter foundation days.

## Setup

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate   # optional but recommended
pip install -r requirements.txt
cp .env.example .env   # edit if needed; defaults work for local dev
uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000/docs` for interactive Swagger docs (FastAPI
generates this automatically from the Pydantic schemas).

## Running tests

```bash
pytest tests/ -v
```

18 tests, all passing as of this writing: tool registry permission
enforcement, safety engine risk-level assignment, full agent orchestrator
flows (doctor search + emergency escalation), and real HTTP round-trips
through `TestClient` (register/login/doctors/agent).

## What was actually verified (not just written)

1. `python3 -c "from app.main import app"` — imports cleanly, no wiring errors.
2. Live server (`uvicorn`) started successfully and responded to `/health`.
3. Full manual flow via `curl`: register → JWT issued → `/doctors` correctly
   401s without a token → `/doctors` returns real seeded data with a token
   → `POST /ai/agent` with `"I have had a fever since yesterday, I want a
   doctor"` returned a real structured `SHOW_DOCTORS` action with real
   doctor records from the database, routed through intent extraction,
   tool selection, the safety engine, tool execution, and LLM explanation
   — the actual pipeline, not a hardcoded response.
4. Same live server, emergency message (`"severe chest pain, cannot
   breathe"`) correctly short-circuited to `risk_level: escalation`,
   `tool_used: null` — no tool executed on the emergency path.
5. Full automated `pytest` suite: 18/18 passing.
6. Audit log inspection confirmed symptom text is never logged verbatim —
   `core/logging.py`'s redaction list caught it as designed.

## What was NOT verified (be aware of these before relying on this)

- **`GeminiProvider` (real Gemini calls) has never actually been called.**
  This sandbox has no network path to `generativelanguage.googleapis.com`.
  The code was written carefully against Gemini's public REST shape, but
  the very first real test of it should be treated as exactly that — a
  first test, not a formality. Set `GEMINI_API_KEY` and try a real request
  before trusting it in any demo.
- **PostgreSQL was never actually connected to.** Everything above ran
  against SQLite (`DATABASE_URL` defaults to a local file). The code is
  dialect-agnostic SQLAlchemy, but "should work with Postgres" and "has
  been run against Postgres" are different claims — only the former is
  true here.
- No load testing, no concurrency testing, no real JWT secret rotation.

## Architecture

```
Flutter
   ↓
FastAPI (app/main.py)
   ↓
Auth/RBAC (app/api/deps.py, app/core/security.py)
   ↓
Agent Orchestrator (app/ai/agent/orchestrator.py)
   ↓
AI Gateway (app/ai/gateway/) ──┬── LLM Provider (Mock now / Gemini when keyed)
                                ├── ML Service (app/ai/ml/) — rule-based prototype today
                                └── RAG (app/ai/rag/) — interfaces only, NOT implemented
   ↓
Safety / Policy Engine (app/ai/safety/policy.py)
   ↓
Tool Registry + Permission enforcement (app/ai/tools/registry.py)
   ↓
HomeDoc Services → Repositories (app/database/repositories/) → SQLAlchemy → SQLite/PostgreSQL
```

## AI subsystem inventory (Day 3.2 §10) — what exists vs. what's real

| Subsystem | Exists (interface) | Actually working |
|---|---|---|
| AI Gateway | ✅ | ✅ (routes to Mock or Gemini) |
| Agent Orchestrator | ✅ | ✅ (full pipeline, one flow) |
| LLM Provider (Mock) | ✅ | ✅ (deterministic, tested) |
| LLM Provider (Gemini) | ✅ | ⚠️ written, unverified — see above |
| Tool Registry | ✅ | ✅ (permission enforcement tested) |
| Permission Manager | ✅ (built into Tool Registry, not separate) | ✅ |
| Safety / Policy Engine | ✅ | ✅ (emergency override tested) |
| Context Manager | ✅ (`agent/memory.py` SessionMemory) | ✅ minimal — session facts only |
| Confirmation Manager | ⚠️ modeled as `requires_confirmation` flag on the response | Not a separate confirm/execute two-step flow yet — Flutter would need to re-call with confirmation, which isn't built |
| AI Audit Logger | ✅ | ✅ (every tool call, redacted) |
| ML Service abstraction | ✅ | ✅ interface + one rule-based model |
| RAG Service | ✅ interface only | ❌ raises `NotImplementedError` by design |
| Embedding Provider | ✅ interface only | ❌ not implemented |

## Tools implemented vs. stubbed (Day 3.2 §14)

- **`search_doctors`** — fully real, hits the actual `DoctorRepository`/database.
- **`get_patient_profile`** — registered, permission-checked, but its body
  returns `success: False, error: "not_implemented"` rather than fake data.
  There is no `patients` table yet.
- All other tools listed in the Day 3.2 prompt (appointments, prescriptions,
  payments, ETA, no-show, etc.) are **not registered at all** — not even as
  stubs. Adding one means: write the tool class, register it in
  `ToolRegistry`, classify its risk in `SafetyEngine`, and add it to
  `AgentOrchestrator._select_tool`'s intent mapping. Nothing else changes.

## ML model documentation (Day 3.2 §18 — no fake clinical claims)

`app/ai/ml/symptom_urgency_model.py` is a **rule-based keyword prototype**,
explicitly flagged `is_prototype=True` on every prediction. It is:
- NOT trained on any clinical dataset.
- NOT validated by a medical professional.
- NOT wired into the agent orchestrator's flow yet — it exists to prove the
  `MLModelProvider`/`ModelRegistry` architecture works, not to make real
  triage decisions today.

## Relationship to the earlier `/ai/triage` contract (Day 3 AI Care feature)

Day 3's Flutter `AiCarePage` was built against a documented
`POST /ai/triage` contract (`docs/backend_contract_ai_triage.md` in the
Flutter project) that this backend does not implement — `/ai/agent` is the
real Day 3.2 replacement, with a genuinely different shape (structured
`actions` list, not a fixed triage-result schema). The Flutter side needs
a corresponding update — see the Flutter-side report for what changed.

## Known limitations / Day 4+ scope

- No Alembic migrations — `Base.metadata.create_all()` is fine for
  foundation work, not for real schema evolution.
- No refresh-token flow — access tokens simply expire (`JWT_EXPIRY_MINUTES`).
- No rate limiting implemented despite being a stated goal (Day 3.2 §33) —
  flagged, not built.
- No prompt-injection-specific test cases yet (Day 3.2 §33) — the
  architecture (code-enforced tool permissions, not LLM-trusted) is the
  actual defense; dedicated adversarial test cases are Day 4+ work.
- Doctor data is seeded in-process on first search (`seed_if_empty`) —
  not how real doctor onboarding will work; a placeholder for demoability.
