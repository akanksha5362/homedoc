/// Structured urgency levels returned by the backend AI Gateway.
///
/// Lives in `shared/models` (not under `features/ai_care/domain`) for the
/// same reason `AppointmentStatus` does: it's consumed by a `shared/ai`
/// widget (`AIRecommendationCard`), and `shared/*` must stay feature-
/// agnostic — nothing in `shared/` may import from `features/*`
/// (see README "Code conventions"). `features/ai_care` re-exports this
/// type from its domain layer so callers within that feature don't need
/// to know it technically lives in `shared`.
///
/// SAFETY RULE (Day 3 AI prompt, Step 4 / UX/UI Architecture v1 §7):
/// these levels drive UI *tone*, never a disease claim. The backend, not
/// this enum, is responsible for actually deciding urgency — this is just
/// the safe vocabulary the client is allowed to render.
enum AIUrgency {
  routine,
  soon,
  urgent,
  emergency,
  selfCare;

  /// Parses the backend's string value, defaulting to the *safer* (more
  /// urgent) option on anything unrecognized rather than silently downgrading
  /// — an unknown urgency value should never be treated as "routine".
  static AIUrgency fromApi(String? value) {
    switch (value) {
      case 'routine':
        return AIUrgency.routine;
      case 'soon':
        return AIUrgency.soon;
      case 'urgent':
        return AIUrgency.urgent;
      case 'emergency':
        return AIUrgency.emergency;
      case 'self_care':
      case 'selfCare':
        return AIUrgency.selfCare;
      default:
        return AIUrgency.urgent;
    }
  }
}
