# Backend Contract — `POST /ai/triage`

**Status: contract only.** No FastAPI backend exists in this repository or
this ZIP. This document is what the Flutter client (`AiCareRemoteDataSource`,
`AITriageRequest`, `AITriageResult`) is written against, so that whoever
builds the actual backend (Architecture v1 §L: FastAPI → AI Gateway → LLM
provider) has an exact, already-agreed shape to implement. Nothing here
should be read as "a backend exists and works" — it does not yet.

## Endpoint

```
POST /ai/triage
Authorization: Bearer <access token>
Content-Type: application/json
```

## Backend architecture the Flutter client assumes

```
Flutter (this repo)
   ↓ POST /ai/triage
FastAPI
   ↓
AI Gateway  (auth, rate limiting, prompt management, logging, cost tracking)
   ↓
Rules engine (hard emergency-keyword thresholds — cannot be overridden by the LLM)
   ↓
LLM provider (Gemini/Vertex AI or equivalent), constrained to structured JSON output
   ↓
Safety layer (disclaimer injection, emergency override, uncertainty framing)
   ↓
Structured JSON response  →  Flutter
```

Per Architecture v1 §L/M, the backend — **not** the Flutter client — is
responsible for:
- Detecting emergency red flags via a rules engine that the LLM cannot override downward.
- Ensuring the LLM never returns a disease diagnosis, only a care pathway recommendation.
- Rate limiting and per-user AI cost tracking.
- Never sending Gemini/LLM API keys or raw prompts to the client.

The Flutter client's only responsibility is to render whatever
`emergency_detected` / `urgency` / `red_flags` the backend returns — it does
not run its own symptom-analysis logic.

## Request body

```json
{
  "symptoms": "I have had a headache and mild fever since yesterday.",
  "duration": "since yesterday",
  "additional_context": null
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `symptoms` | string | yes | Free-text patient description. Never logged by the client (see Security section). |
| `duration` | string \| null | no | Free-text, not a structured enum at this stage. |
| `additional_context` | string \| null | no | Reserved for future follow-up-question answers (Day 2 §7 — targeted follow-ups are not yet implemented client-side; this field exists so the contract doesn't need to change when they are). |

## Response body

```json
{
  "summary": "Your symptoms may be consistent with several common causes.",
  "urgency": "routine",
  "recommendation": "Consider consulting a general physician if symptoms persist.",
  "reasoning": "The duration and symptoms provided do not indicate an obvious emergency, but more information would help.",
  "red_flags": [],
  "next_step": "Monitor symptoms and consider a doctor consultation if they worsen or persist beyond a few days.",
  "is_uncertain": true,
  "emergency_detected": false,
  "disclaimer": "AI guidance, not a diagnosis."
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `summary` | string | yes | Plain-language restatement, never a disease name. |
| `urgency` | `"routine" \| "soon" \| "urgent" \| "emergency"` | yes | Client defaults unrecognized values to `"urgent"` (fail-safe, not `"routine"`) — see `AIUrgency.fromApi`. |
| `recommendation` | string | yes | Care pathway language only (see "Safe language" below). |
| `reasoning` | string | yes | Why this recommendation, in plain language. |
| `red_flags` | string[] | yes (may be empty) | Short phrases, not full sentences. |
| `next_step` | string | yes | Single actionable next step. |
| `is_uncertain` | bool | yes | Client defaults to `true` if missing — never assume confidence. |
| `emergency_detected` | bool | yes | Client defaults to `false` if missing, but the backend must never omit this field in practice — it's the field the client fully trusts to trigger the full-screen `EmergencyWarning`. |
| `disclaimer` | string | no (has a client-side fallback) | Backend should still always send it — don't rely on the client default in production. |

## Safe language requirements (backend responsibility)

The backend/LLM prompt must never produce:
- "You have [disease]." / "This confirms [disease]."
- Any wording implying certainty from a text description alone.

And should prefer:
- "may be associated with…", "could have several causes…",
  "consider speaking with a healthcare professional…",
  "seek urgent medical attention if…"

This is a backend/prompt responsibility — the Flutter client has no way to
enforce it beyond rendering `is_uncertain` and `disclaimer` visibly, which
it does unconditionally (`AIRecommendationCard` cannot be rendered without
a disclaimer string).

## Error responses

| Status | Client behavior |
|---|---|
| `401` | `AuthenticationException` — existing app-wide handling (session expiry). |
| `422` | `ValidationException` — e.g. empty `symptoms`. Client also validates non-empty before sending. |
| `429` | `RateLimitException` — existing app-wide handling. |
| `502` / `503` / `504` / any `5xx` on `/ai/*` | `AIServiceException` — client shows "Care guidance is temporarily unavailable" + a direct link back to doctor booking (UX/UI Architecture v1 §6: "the core loop must survive an AI outage"). |
| Malformed/non-JSON-object body | `AIServiceException` — thrown client-side in `AiCareRemoteDataSource`, never crashes the UI. |

## Explicitly NOT implemented anywhere (client or backend)

- The actual FastAPI service and AI Gateway.
- The rules-engine emergency-keyword detection (currently: the client can
  only ever be as safe as what the backend sends — there is no backend).
- Multi-turn targeted follow-up questions (Day 2 §7's "2–4 targeted
  follow-up questions") — `additional_context` is reserved for this, unused today.
- RAG/knowledge grounding, prompt versioning, model evaluation, and the AI
  Agent tool layer (search doctors, book appointment, etc. — see README
  "AI Agent readiness").
