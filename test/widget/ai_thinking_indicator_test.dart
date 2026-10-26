import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/shared/ai/ai_thinking_indicator.dart';

void main() {
  testWidgets('renders the caller-supplied message (no hardcoded default)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AIThinkingIndicator(message: 'Thinking through what you\'ve shared…')),
      ),
    );

    expect(find.text('Thinking through what you\'ve shared…'), findsOneWidget);
  });
}
