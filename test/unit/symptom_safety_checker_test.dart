import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_care/data/models/conversational_triage_request.dart';
import 'package:homedoc/features/ai_care/domain/safety/symptom_safety_checker.dart';

void main() {
  group('SymptomSafetyChecker', () {
    test('intercepts a positively reported emergency trigger', () {
      final result = SymptomSafetyChecker.evaluate('I have severe chest pain');

      expect(result.isEmergency, isTrue);
      expect(result.matchedTriggers, isNotEmpty);
    });

    test('does not flag an explicitly denied trigger', () {
      final result = SymptomSafetyChecker.evaluate('I do not have chest pain');

      expect(result.isEmergency, isFalse);
    });

    test('does not treat “not only” as a denial', () {
      final result = SymptomSafetyChecker.evaluate(
        'I have not only chest pain but also shortness of breath',
      );

      expect(result.isEmergency, isTrue);
    });

    test('does not let a denial suppress a separate symptom after a comma', () {
      final result = SymptomSafetyChecker.evaluate(
        'I do not have chest pain, but I am gasping for air',
      );

      expect(result.isEmergency, isTrue);
    });

    test('does not let a denial suppress a contrasting symptom clause', () {
      final result = SymptomSafetyChecker.evaluate(
        'No chest pain but I cannot breathe',
      );

      expect(result.isEmergency, isTrue);
    });
  });

  test('serializes the conversational triage contract field names', () {
    const request = ConversationalTriageRequest(
      chiefComplaint: 'Headache',
      duration: 'About a week',
      severity: 'Moderate',
      associatedSymptoms: ['Nausea', 'Dizziness'],
      medicalHistory: 'Hypertension',
    );

    expect(request.toJson(), {
      'session_id': null,
      'chief_complaint': 'Headache',
      'duration': 'About a week',
      'severity': 'Moderate',
      'associated_symptoms': ['Nausea', 'Dizziness'],
      'medical_history': 'Hypertension',
      'age_context': null,
    });
  });
}
