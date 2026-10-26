/// Endpoint paths grouped by domain exactly as defined in
/// HomeDoc AI Architecture v1, Section K. Kept as plain string constants
/// (not an enum) so repositories can compose path params simply.
///
/// Only endpoints actually used by foundation/MVP-first features are
/// listed today — add the rest alongside the feature that needs them,
/// rather than pre-declaring the entire Day 1 API surface unused.
class ApiEndpoints {
  ApiEndpoints._();

  // /auth
  // otpRequest/otpVerify/refresh reflect the ORIGINAL planned OTP flow
  // (Architecture v1 §K) — the real backend built in Day 3.2/Day 4 does
  // NOT implement OTP; it uses phone+password (register/login below).
  // Kept here, unused, as a documented placeholder for when real SMS OTP
  // delivery is added — do not wire these to anything until it exists.
  static const otpRequest = '/auth/otp/request';
  static const otpVerify = '/auth/otp/verify';
  static const refresh = '/auth/refresh';

  // Real, working endpoints (backend/app/api/routes/auth.py) — Day 4.
  static const register = '/auth/register';
  static const login = '/auth/login';

  // /patients
  static const patientMe = '/patients/me';

  // /doctors
  static const doctors = '/doctors';
  static String doctorById(String id) => '/doctors/$id';

  // /appointments
  static const appointments = '/appointments';
  static String appointmentStatus(String id) => '/appointments/$id/status';

  // /ai — routed through the backend's AI Gateway (Architecture v1 §L).
  // Flutter never talks to Gemini/any LLM provider directly; these are
  // the only AI-related URLs that exist client-side.
  //
  // aiTriage: single-shot symptom triage (Day 3's AiCarePage), documented
  // in docs/backend_contract_ai_triage.md.
  // aiAgent: the Day 3.2 agent architecture — natural-language message in,
  // structured AgentResponse (message + risk_level + actions) out. This is
  // the real, running backend (see backend/README.md); aiTriage's backend
  // was never built and remains contract-only.
  static const aiTriage = '/ai/triage';
  static const aiAgent = '/ai/agent';
}
