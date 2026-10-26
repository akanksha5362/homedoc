import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_care/presentation/widgets/symptom_input.dart';

void main() {
  testWidgets('SymptomInput renders symptoms and duration fields with given labels', (tester) async {
    final symptomsController = TextEditingController();
    final durationController = TextEditingController();
    addTearDown(symptomsController.dispose);
    addTearDown(durationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SymptomInput(
            symptomsController: symptomsController,
            durationController: durationController,
            symptomsLabel: 'What are you experiencing?',
            symptomsHint: 'e.g. headache',
            durationLabel: 'How long?',
          ),
        ),
      ),
    );

    expect(find.text('What are you experiencing?'), findsOneWidget);
    expect(find.text('How long?'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'headache and fever');
    expect(symptomsController.text, 'headache and fever');
  });
}
