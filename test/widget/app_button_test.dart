import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/shared/widgets/buttons/app_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AppButton', () {
    testWidgets('renders label and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AppButton(label: 'Continue', onPressed: () => tapped = true)),
      );

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows a spinner and ignores taps while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AppButton(label: 'Continue', isLoading: true, onPressed: () => tapped = true)),
      );

      expect(find.text('Continue'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(wrap(const AppButton(label: 'Continue', onPressed: null)));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
