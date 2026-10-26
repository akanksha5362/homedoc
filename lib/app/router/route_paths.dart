/// Centralized route paths (Day 3 §11). Never hardcode a path string at a
/// call site — reference these constants so a path rename is one-line.
class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/role-selection';
  static const auth = '/auth';

  static const doctorLogin = '/doctor-login';
  static const adminLogin = '/admin-login';
  static const patientRoot = '/patient';
  static const patientHome = '/patient/home';
  static const patientCare = '/patient/care';
  static const patientAppointments = '/patient/appointments';
  static const patientBookAppointment = '/patient/book-appointment';
  static const patientHealth = '/patient/health';
  static const patientProfile = '/patient/profile';
  static const patientAiCare = '/patient/ai-care';
  static const patientAiAssistant = '/patient/ai-assistant';

  static const doctorRoot = '/doctor';
  static const doctorToday = '/doctor/today';
  static const doctorProfile = '/doctor/profile';

  static const adminRoot = '/admin';
}
