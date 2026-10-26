// Basic smoke test for HomeDocApp.
//
// The previous version of this file was the unmodified `flutter create`
// counter-app template — it pumped `HomeDocApp` with no `ProviderScope`
// (which `HomeDocApp.build` requires, since it reads `routerProvider`) and
// asserted on counter-app UI ('0', '1', a '+' icon) that doesn't exist
// anywhere in this app. It could never have passed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/app/app.dart';
import 'package:homedoc/app/config/app_config.dart';
import 'package:homedoc/app/config/environment.dart';
import 'package:homedoc/shared/providers/auth_provider.dart';

void main() {
  testWidgets('HomeDocApp launches on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mirrors main.dart's composition-root override — appConfigProvider
          // throws UnimplementedError if left unoverridden.
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(Environment.development),
          ),
        ],
        child: const HomeDocApp(),
      ),
    );

    // Before the async session-restore check resolves, RouteGuards' loading
    // guard keeps the app on the splash screen — see route_guards.dart.
    expect(find.text('HomeDoc AI'), findsOneWidget);
  });
}
