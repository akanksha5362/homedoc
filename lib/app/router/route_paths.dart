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
  static const patientNotifications = '/patient/notifications';
  static const patientDoctorTracking = '/patient/tracking';
  static const patientVideoConsultation = '/patient/video-consultation';
  static const patientBookAppointment = '/patient/book-appointment';
  static const patientHealth = '/patient/health';
  static const patientReminders = '/patient/reminders';
  static const patientChatList = '/patient/chat';
  static const patientChatConversation = '/patient/chat-conversation';
  static const patientProfile = '/patient/profile';
  static const patientFamilyProfiles = '/patient/family-profiles';
  static const patientAiCare = '/patient/ai-care';
  static const patientAiAssistant = '/patient/ai-assistant';
  static const patientAiSearch = '/patient/ai-search';
  static const patientEmergency = '/patient/emergency';

  static const doctorRoot = '/doctor';
  static const doctorToday = '/doctor/today';
  static const doctorProfile = '/doctor/profile';
  static const doctorAvailability = '/doctor/availability';
  static const doctorChatList = '/doctor/chat';

  static const adminRoot = '/admin';
}
