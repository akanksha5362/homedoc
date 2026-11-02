
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:homedoc/app/app.dart';
import 'package:homedoc/app/router/app_router.dart';
import 'package:homedoc/app/router/route_paths.dart';
import 'package:homedoc/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('HomeDocApp launches on the splash screen', (
      WidgetTester tester,
      ) async {
    // Use a test router so Firebase authentication is not required.
    final testRouter = GoRouter(
      initialLocation: RoutePaths.splash,
      routes: [
        GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RoutePaths.onboarding,
          builder: (context, state) => const Scaffold(
            body: Text('Onboarding test route'),
          ),
        ),
      ],
    );

    addTearDown(testRouter.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(testRouter),
        ],
        child: const HomeDocApp(),
      ),
    );

    expect(
      find.text('Healthcare at your doorstep.'),
      findsOneWidget,
    );

    // Allow the splash screen's 3-second navigation timer to complete.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
