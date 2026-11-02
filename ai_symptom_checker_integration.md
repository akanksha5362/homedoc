# AI Symptom Checker integration

The guided checker now sends its collected answers to the documented
`POST /ai/triage/conversational` contract in
`AI_HEALTHCARE_BACKEND_CONTRACT.md`. The Flutter source snapshot does not
include the backend, so the endpoint could not be checked against a running
service.

## Frontend behavior

- Opens in guided mode and collects chief complaint, duration, severity,
  associated symptoms, and patient-entered medical history.
- Runs the local emergency keyword check on each answer and on direct-form
  submissions. Explicitly denied triggers such as “I do not have chest pain”
  are not treated as a positive report; positively reported contract triggers
  still interrupt the flow.
- Routes emergency actions to the existing Emergency Options screen. It does
  not claim to call or contact emergency services itself.
- Uses the conversational endpoint response for urgency and recommendations.
  Missing or malformed safety fields are treated as a service error.
- Shows a retryable error when the service fails. It no longer fabricates a
  triage result or urgency recommendation while offline.
- Shows only matching, non-demo doctor profiles from the existing verified
  directory. It does not fall back to unrelated doctors or display synthetic
  fees or hospital names.

## Backend dependencies

Implement the supplied contract route:

```http
POST /ai/triage/conversational
Authorization: Bearer <JWT_ACCESS_TOKEN>
Content-Type: application/json
```

The request uses `session_id`, `chief_complaint`, `duration`, `severity`,
`associated_symptoms`, `medical_history`, and `age_context`. The app does not
currently collect age or date of birth, so it sends `age_context: null`; the
backend must accept null (or the frontend contract must be updated before age
is collected). `session_id` is null for a new assessment.

The response must include non-empty `summary`, `urgency`, `why_assigned`,
`recommendation`, `next_step`, and `disclaimer`, plus typed
`red_flags`, `is_uncertain`, and `emergency_detected`. When `urgency` is
`emergency`, the client escalates to the Emergency Options screen even if the
boolean flag is inconsistent. The backend must enforce its own emergency
rules, authentication, and authorization; the client keyword check is an
additional short-circuit, not a replacement for server policy.

The separate Direct Form still uses the pre-existing `POST /ai/triage`
integration from the supplied source. Its referenced
`docs/backend_contract_ai_triage.md` was not among the supplied files, so its
request/response contract and backend availability remain unverified. The
guided flow uses only the conversational route documented in the supplied AI
contract.
