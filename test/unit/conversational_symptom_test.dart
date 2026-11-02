import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_request.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_result.dart';
import 'package:homedoc/features/ai_care/data/models/conversational_triage_request.dart';
import 'package:homedoc/features/ai_care/data/models/conversational_symptom_model.dart';
import 'package:homedoc/features/ai_care/domain/repositories/ai_care_repository.dart';
import 'package:homedoc/features/ai_care/domain/safety/symptom_safety_checker.dart';
import 'package:homedoc/features/ai_care/presentation/providers/conversational_symptom_provider.dart';
import 'package:homedoc/shared/models/ai_urgency.dart';

class _FakeAiCareRepo implements AiCareRepository {
  AITriageResult? resultToReturn;

  @override
  Future<AITriageResult> analyzeSymptoms(AITriageRequest request) async {
    return resultToReturn ??
        const AITriageResult(
          summary: 'Assessment completed.',
          urgency: AIUrgency.routine,
          recommendation: 'Consult a physician.',
          reasoning: 'Non-emergency indications.',
          redFlags: [],
          nextStep: 'Schedule visit.',
          isUncertain: true,
          emergencyDetected: false,
          suggestedSpecialty: 'General Physician',
        );
  }

  @override
  Future<AITriageResult> analyzeConversationalSymptoms(
    ConversationalTriageRequest request,
  ) =>
      analyzeSymptoms(AITriageRequest(symptoms: request.chiefComplaint));
}

void main() {
  group('SymptomSafetyChecker', () {
    test('detects cardiac emergency patterns', () {
      final res1 = SymptomSafetyChecker.evaluate('I feel severe chest pain and pressure');
      expect(res1.isEmergency, isTrue);
      expect(res1.matchedTriggers.first, contains('Cardiac'));

      final res2 = SymptomSafetyChecker.evaluate('Heart attack symptoms with arm pain');
      expect(res2.isEmergency, isTrue);
    });

    test('detects respiratory distress patterns', () {
      final res = SymptomSafetyChecker.evaluate('Patient cannot breathe and has blue lips');
      expect(res.isEmergency, isTrue);
      expect(res.matchedTriggers.first, contains('Respiratory'));
    });

    test('detects acute neurological and stroke patterns', () {
      final res = SymptomSafetyChecker.evaluate('Sudden facial drooping and loss of consciousness');
      expect(res.isEmergency, isTrue);
      expect(res.matchedTriggers.first, contains('Neurological'));
    });

    test('allows non-emergency clinical descriptions without false alarm', () {
      final res1 = SymptomSafetyChecker.evaluate('Mild headache since morning after reading');
      expect(res1.isEmergency, isFalse);

      final res2 = SymptomSafetyChecker.evaluate('Knee pain while walking upstairs');
      expect(res2.isEmergency, isFalse);

      final res3 = SymptomSafetyChecker.evaluate('Acne and skin itching on forearm');
      expect(res3.isEmergency, isFalse);
    });
  });

  group('ConversationalTriageNotifier', () {
    late _FakeAiCareRepo repo;
    late ConversationalTriageNotifier notifier;

    setUp(() {
      repo = _FakeAiCareRepo();
      notifier = ConversationalTriageNotifier(repo);
    });

    test('initializes with chief complaint stage and welcome prompt', () {
      expect(notifier.state.stage, SymptomStage.chiefComplaint);
      expect(notifier.state.messages, isNotEmpty);
      expect(notifier.state.messages.first.isUser, isFalse);
      expect(notifier.state.messages.first.suggestedChips, isNotEmpty);
    });

    test('progresses through all 5 conversational stages on valid input', () async {
      // Step 1: Chief complaint
      await notifier.submitAnswer('Recurring throbbing headaches');
      expect(notifier.state.stage, SymptomStage.duration);
      expect(notifier.state.chiefComplaint, 'Recurring throbbing headaches');

      // Step 2: Duration
      await notifier.submitAnswer('About a week');
      expect(notifier.state.stage, SymptomStage.severity);
      expect(notifier.state.duration, 'About a week');

      // Step 3: Severity
      await notifier.submitAnswer('Moderate (limits some daily activities)');
      expect(notifier.state.stage, SymptomStage.associatedSymptoms);
      expect(notifier.state.severity, 'Moderate (limits some daily activities)');

      // Step 4: Associated symptoms
      await notifier.submitAnswer('Nausea / dizziness');
      expect(notifier.state.stage, SymptomStage.review);
      expect(notifier.state.associatedSymptoms, contains('Nausea / dizziness'));

      // Step 5: Clinical context & final review triggers triage
      await notifier.submitAnswer('No pre-existing conditions');
      expect(notifier.state.stage, SymptomStage.complete);
      expect(notifier.state.triageResult, isNotNull);
      expect(notifier.state.hasEmergency, isFalse);
    });

    test('immediately intercepts emergency input at any step', () async {
      await notifier.submitAnswer('Severe chest pain and choking');
      expect(notifier.state.stage, SymptomStage.emergency);
      expect(notifier.state.hasEmergency, isTrue);
      expect(notifier.state.emergencyResult, isNotNull);
      expect(notifier.state.emergencyResult!.isEmergency, isTrue);
    });

    test('reset clears dialogue and returns to initial chief complaint state', () async {
      await notifier.submitAnswer('Fever');
      expect(notifier.state.stage, SymptomStage.duration);

      notifier.reset();
      expect(notifier.state.stage, SymptomStage.chiefComplaint);
      expect(notifier.state.chiefComplaint, isNull);
    });
  });
}
