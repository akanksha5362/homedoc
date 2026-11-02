import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/states/app_empty_state.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../features/ai_care/presentation/pages/ai_care_page.dart';
import '../../features/ai_search/presentation/pages/ai_health_search_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/care/presentation/pages/care_page.dart';
import '../../features/doctor/presentation/pages/doctor_today_page.dart';
import '../../features/health/presentation/pages/health_page.dart';
import '../../features/family/presentation/pages/family_profiles_page.dart';
import '../../features/home/presentation/pages/patient_home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'route_guards.dart';
import 'route_paths.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/doctor_login_page.dart';
import '../../features/auth/presentation/pages/admin_login_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/book_appointment_page.dart';
import '../../features/tracking/presentation/pages/doctor_tracking_page.dart';
import '../../features/doctor/presentation/pages/doctor_profile_page.dart';
import '../../features/doctor/presentation/pages/doctor_availability_page.dart';
import '../../features/reminders/presentation/pages/medication_reminders_page.dart';
import '../../features/consultation/presentation/pages/video_consultation_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_conversation_page.dart';
import '../../features/chat/data/models/chat_conversation_model.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/notifications/presentation/pages/notification_centre_page.dart';

/// Helper class to bridge Riverpod state changes to a Listenable for GoRouter
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      return RouteGuards.redirectFor(
        location: state.matchedLocation,
        authState: authState,
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.roleSelection,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: RoutePaths.auth,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.doctorLogin,
        builder: (context, state) => const DoctorLoginPage(),
      ),
      GoRoute(
        path: RoutePaths.adminLogin,
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: RoutePaths.patientHome,
        builder: (context, state) => const PatientHomePage(),
      ),
      GoRoute(
        path: RoutePaths.patientCare,
        builder: (context, state) => const CarePage(),
      ),
      GoRoute(
        path: RoutePaths.patientAppointments,
        builder: (context, state) => const AppointmentsPage(),
      ),
      GoRoute(
        path: RoutePaths.patientNotifications,
        builder: (context, state) => const NotificationCentrePage(),
      ),
      GoRoute(
        path: RoutePaths.patientDoctorTracking,
        builder: (context, state) {
          final appointment = state.extra;
          if (appointment is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Appointment details are unavailable.')),
            );
          }
          return DoctorTrackingPage(appointment: appointment);
        },
      ),
      GoRoute(
        path: RoutePaths.patientVideoConsultation,
        builder: (context, state) {
          final appointment = state.extra as Map<String, dynamic>?;
          return VideoConsultationPage(appointment: appointment);
        },
      ),
      GoRoute(
        path: RoutePaths.patientBookAppointment,
        builder: (context, state) {
          final doctorId =
              state.uri.queryParameters['doctorId'] ??
                  (state.extra is String ? state.extra as String : null);
          return BookAppointmentPage(initialDoctorId: doctorId);
        },
      ),
      GoRoute(
        path: RoutePaths.patientHealth,
        builder: (context, state) => const HealthPage(),
      ),
      GoRoute(
        path: RoutePaths.patientReminders,
        builder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return MedicationRemindersPage(
            initialMedicineName: queryParams['medicine'],
            initialDosage: queryParams['dosage'],
            initialDoctor: queryParams['doctor'],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.patientChatList,
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: RoutePaths.patientChatConversation,
        builder: (context, state) {
          final conversation = state.extra as ConversationModel?;
          if (conversation == null) {
            return const ChatListPage();
          }
          return ChatConversationPage(conversation: conversation);
        },
      ),
      GoRoute(
        path: RoutePaths.patientProfile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.patientFamilyProfiles,
        builder: (context, state) => const FamilyProfilesPage(),
      ),
      GoRoute(
        path: RoutePaths.patientAiCare,
        builder: (context, state) => const AiCarePage(),
      ),
      GoRoute(
        path: RoutePaths.patientAiAssistant,
        builder: (context, state) => const AiAssistantPage(),
      ),
      GoRoute(
        path: RoutePaths.patientAiSearch,
        builder: (context, state) {
          final query = state.uri.queryParameters['query'];
          return AiHealthSearchPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: RoutePaths.patientEmergency,
        builder: (context, state) => const EmergencyPage(),
      ),
      GoRoute(
        path: RoutePaths.doctorToday,
        builder: (context, state) => const DoctorTodayPage(),
      ),
      GoRoute(
        path: RoutePaths.doctorProfile,
        builder: (context, state) => const DoctorProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.doctorAvailability,
        builder: (context, state) => const DoctorAvailabilityPage(),
      ),
      GoRoute(
        path: RoutePaths.doctorChatList,
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: RoutePaths.adminRoot,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Admin')),
          body: const AppEmptyState(
            message: 'The admin dashboard is not built yet.',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ),
      ),
    ],
  );
});
