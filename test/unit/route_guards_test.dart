import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/app/router/route_guards.dart';
import 'package:homedoc/app/router/route_paths.dart';
import 'package:homedoc/shared/models/user_model.dart';
import 'package:homedoc/shared/providers/auth_provider.dart';

void main() {
  group('RouteGuards', () {
    test('stays on splash while auth state is loading', () {
      const state = AuthState(isLoading: true);
      final redirect = RouteGuards.redirectFor(location: RoutePaths.splash, authState: state);
      expect(redirect, isNull);
    });

    test('redirects to splash if not on splash while loading', () {
      const state = AuthState(isLoading: true);
      final redirect = RouteGuards.redirectFor(location: RoutePaths.patientHome, authState: state);
      expect(redirect, RoutePaths.splash);
    });

    test('redirects signed-out user to /auth', () {
      const state = AuthState(user: null, isLoading: false);
      final redirect = RouteGuards.redirectFor(location: RoutePaths.patientHome, authState: state);
      expect(redirect, RoutePaths.auth);
    });

    test('redirects signed-in patient away from /auth to patient home', () {
      final state = AuthState(
        user: UserModel(id: '1', role: UserRole.patient, displayName: 'Test'),
        isLoading: false,
      );
      final redirect = RouteGuards.redirectFor(location: RoutePaths.auth, authState: state);
      expect(redirect, RoutePaths.patientHome);
    });

    test('blocks a patient from a doctor-only route', () {
      final state = AuthState(
        user: UserModel(id: '1', role: UserRole.patient, displayName: 'Test'),
        isLoading: false,
      );
      final redirect = RouteGuards.redirectFor(location: RoutePaths.doctorToday, authState: state);
      expect(redirect, RoutePaths.patientHome);
    });

    test('allows a signed-in patient to stay on a patient route', () {
      final state = AuthState(
        user: UserModel(id: '1', role: UserRole.patient, displayName: 'Test'),
        isLoading: false,
      );
      final redirect = RouteGuards.redirectFor(location: RoutePaths.patientCare, authState: state);
      expect(redirect, isNull);
    });
  });
}
