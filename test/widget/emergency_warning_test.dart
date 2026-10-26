import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/shared/healthcare/emergency_warning.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders message, red flags, and fires onAction when tapped', (tester) async {
    var actionTapped = false;

    await tester.pumpWidget(
      wrap(EmergencyWarning(
        message: 'This may need urgent attention',
        redFlags: const ['Chest pain', 'Shortness of breath'],
        redFlagsLabel: 'Things to watch for',
        actionLabel: 'Get emergency help',
        onAction: () => actionTapped = true,
      )),
    );

    expect(find.text('This may need urgent attention'), findsOneWidget);
    expect(find.textContaining('Chest pain'), findsOneWidget);
    expect(find.textContaining('Shortness of breath'), findsOneWidget);

    await tester.tap(find.text('Get emergency help'));
    expect(actionTapped, isTrue);
  });

  testWidgets('omits the red flags section when the list is empty', (tester) async {
    await tester.pumpWidget(
      wrap(EmergencyWarning(
        message: 'This may need urgent attention',
        redFlags: const [],
        redFlagsLabel: 'Things to watch for',
        actionLabel: 'Get emergency help',
        onAction: () {},
      )),
    );

    expect(find.text('Things to watch for'), findsNothing);
  });

  testWidgets('works with no redFlags/redFlagsLabel args at all — the AI Assistant call site '
      '(Day 3.2) does not currently receive red flags from the backend', (tester) async {
    await tester.pumpWidget(
      wrap(EmergencyWarning(
        message: 'This may be a medical emergency',
        actionLabel: 'Get emergency help',
        onAction: () {},
      )),
    );

    expect(find.text('This may be a medical emergency'), findsOneWidget);
    expect(find.text('Get emergency help'), findsOneWidget);
  });
}
