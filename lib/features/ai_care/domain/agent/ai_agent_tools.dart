/// -----------------------------------------------------------------------
/// AI AGENT FOUNDATION — INTERFACES ONLY. NOT IMPLEMENTED. NOT WIRED IN.
/// -----------------------------------------------------------------------
/// Nothing in this file is called from anywhere in the app today. It
/// exists solely so a future tool-using AI agent (built on the FastAPI
/// backend, per Architecture v1 §L) has an already-agreed Flutter-side
/// contract to target, without pretending an agent exists now.
///
/// The agent itself — orchestration, tool selection, multi-step reasoning
/// — belongs on the backend, not in Flutter (Day 3 AI prompt, Step 12:
/// "The agent should eventually be implemented on the backend. Flutter
/// should remain the client."). These interfaces model what the *client*
/// would need to expose if/when the backend starts calling back into
/// client-known actions, or what a future `/ai/agent` endpoint's tool
/// results might look like when surfaced in the UI.
///
/// Do NOT implement these speculatively. Implement a tool only when a
/// real feature needs it (e.g. `DoctorSearchTool` becomes real once
/// doctor search itself is built) — see README "AI Agent readiness".
/// -----------------------------------------------------------------------
library;

/// A single tool the future backend AI agent could invoke. Every real
/// tool (once built) will look roughly like this — kept generic and
/// non-dynamic-typed at the interface level to avoid an early framework
/// decision the project doesn't need yet (Step 20: don't overengineer).
abstract class AiAgentTool<TInput, TOutput> {
  /// Stable identifier the backend would reference (e.g. "search_doctors").
  String get toolName;

  Future<TOutput> execute(TInput input);
}

/// Finds doctors matching criteria derived from AI triage (specialty,
/// location, availability). Corresponds to `GET /doctors` (Architecture v1
/// §K) — a tool wrapper around an endpoint that already exists in the
/// contract, just not yet exposed as an agent-callable tool.
abstract class DoctorSearchTool implements AiAgentTool<Object, Object> {}

/// Checks a specific doctor's open slots. Corresponds to appointment
/// availability, not yet a dedicated endpoint (today's `/appointments`
/// covers booking, not availability querying — see Day 4+ scope).
abstract class AppointmentAvailabilityTool implements AiAgentTool<Object, Object> {}

/// Books an appointment on the patient's behalf. Deliberately the tool
/// most likely to need an explicit human-confirmation step before
/// execution, per Day 3's medical-safety rule ("AI must have a clear
/// human escalation path" / never fully autonomous for booking).
abstract class BookAppointmentTool implements AiAgentTool<Object, Object> {}

/// Retrieves a patient's own consent-gated health records for AI context
/// (Architecture v1 §T — the consent engine, not this tool, decides what's
/// accessible; this tool only ever asks for what consent already permits).
abstract class HealthRecordTool implements AiAgentTool<Object, Object> {}

/// Escalates directly to the Emergency flow (`EmergencyAction` /
/// `EmergencyWarning` already exist in the UI — see Step 5 of this
/// implementation). This tool would let a future backend agent trigger
/// that same client-side flow programmatically instead of only via a
/// structured `emergency_detected: true` triage response.
abstract class EmergencyEscalationTool implements AiAgentTool<Object, Object> {}
