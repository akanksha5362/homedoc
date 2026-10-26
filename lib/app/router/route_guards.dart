import '../../shared/models/user_model.dart';
import '../../shared/providers/auth_provider.dart';
import 'route_paths.dart';

/// Controls authentication and role-based navigation.
class RouteGuards {
  RouteGuards._();

  static String? redirectFor({
    required String location,
    required AuthState authState,
  }) {
    // 1. SESSION RESTORATION
    if (authState.isLoading) {
      return location == RoutePaths.splash ? null : RoutePaths.splash;
    }

    final isOnSplash = location == RoutePaths.splash;
    final isOnOnboarding = location == RoutePaths.onboarding;
    final isOnRoleSelection = location == RoutePaths.roleSelection;
    final isOnDoctorLogin = location == RoutePaths.doctorLogin;
    final isOnAdminLogin = location == RoutePaths.adminLogin;
    final isOnAuth = location == RoutePaths.auth;

    // 2. AUTHENTICATED USER
    if (authState.isSignedIn && authState.user != null) {
      final user = authState.user!;

      // Signed-in users should go to their own dashboard
      // instead of seeing onboarding, role selection, or login.
      if (isOnSplash ||
          isOnOnboarding ||
          isOnRoleSelection ||
          isOnAuth ||
          isOnDoctorLogin ||
          isOnAdminLogin) {
        return _rootForRole(user.role);
      }

      // Doctor-only pages
      if (location.startsWith(RoutePaths.doctorRoot) &&
          user.role != UserRole.doctor) {
        return _rootForRole(user.role);
      }

      // Patient-only pages
      if (location.startsWith(RoutePaths.patientRoot) &&
          user.role != UserRole.patient) {
        return _rootForRole(user.role);
      }

      // Admin-only pages
      if (location.startsWith(RoutePaths.adminRoot) &&
          user.role != UserRole.admin) {
        return _rootForRole(user.role);
      }

      return null;
    }

    // 3. SIGNED-OUT USER
    // Allow the public entry screens, including role selection.
    if (isOnSplash ||
        isOnOnboarding ||
        isOnRoleSelection ||
        isOnAuth ||
        isOnDoctorLogin ||
        isOnAdminLogin) {
      return null;
    }

    // Signed-out users cannot access dashboard routes.
    return RoutePaths.roleSelection;
  }

  // ROLE LANDING PAGES
  static String _rootForRole(UserRole role) {
    return switch (role) {
      UserRole.patient => RoutePaths.patientHome,
      UserRole.doctor => RoutePaths.doctorToday,
      UserRole.admin => RoutePaths.adminRoot,
      UserRole.pharmacy || UserRole.lab => RoutePaths.auth,
    };
  }
}
