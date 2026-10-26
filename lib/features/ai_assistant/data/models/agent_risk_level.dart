/// Mirrors backend/app/schemas/agent.py RiskLevel exactly. Keep these two
/// enums in sync by hand — there is no shared schema-generation step
/// between the Python and Dart sides at foundation stage (Day 4+ could
/// add OpenAPI-generated clients; not done today per the "don't
/// overengineer" instruction for a two-person team's Day 3.2 scope).
enum AgentRiskLevel {
  info,
  low,
  confirm,
  sensitive,
  escalation;

  static AgentRiskLevel fromApi(String? value) {
    switch (value) {
      case 'info':
        return AgentRiskLevel.info;
      case 'low':
        return AgentRiskLevel.low;
      case 'confirm':
        return AgentRiskLevel.confirm;
      case 'sensitive':
        return AgentRiskLevel.sensitive;
      case 'escalation':
        return AgentRiskLevel.escalation;
      default:
        // Fail-safe: an unrecognized risk level is treated as requiring
        // confirmation, never as "info" — same fail-toward-caution
        // principle as AIUrgency.fromApi.
        return AgentRiskLevel.confirm;
    }
  }
}

/// Mirrors backend/app/schemas/agent.py ActionType. Only a subset is
/// actually produced by the backend today (SHOW_DOCTORS, EMERGENCY) — the
/// rest are modeled now so Flutter's rendering switch is exhaustive and
/// doesn't need to change shape when the backend adds more tools/actions.
enum AgentActionType {
  showDoctors,
  showAppointments,
  bookAppointment,
  showPrescription,
  startVideo,
  trackDoctor,
  setReminder,
  requestHomeVisit,
  escalateToDoctor,
  emergency,
  unknown; // never produced by the backend — a client-side fallback only

  static AgentActionType fromApi(String? value) {
    switch (value) {
      case 'SHOW_DOCTORS':
        return AgentActionType.showDoctors;
      case 'SHOW_APPOINTMENTS':
        return AgentActionType.showAppointments;
      case 'BOOK_APPOINTMENT':
        return AgentActionType.bookAppointment;
      case 'SHOW_PRESCRIPTION':
        return AgentActionType.showPrescription;
      case 'START_VIDEO':
        return AgentActionType.startVideo;
      case 'TRACK_DOCTOR':
        return AgentActionType.trackDoctor;
      case 'SET_REMINDER':
        return AgentActionType.setReminder;
      case 'REQUEST_HOME_VISIT':
        return AgentActionType.requestHomeVisit;
      case 'ESCALATE_TO_DOCTOR':
        return AgentActionType.escalateToDoctor;
      case 'EMERGENCY':
        return AgentActionType.emergency;
      default:
        return AgentActionType.unknown;
    }
  }
}
