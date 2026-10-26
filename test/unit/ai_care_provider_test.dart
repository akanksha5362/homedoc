import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/core/errors/app_exception.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_request.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_result.dart';
import 'package:homedoc/features/ai_care/domain/repositories/ai_care_repository.dart';
import 'package:homedoc/features/ai_care/presentation/providers/ai_care_provider.dart';
import 'package:homedoc/shared/models/ai_urgency.dart';

class _FakeRepository implements AiCareRepository {
  _FakeRepository({this.result, this.error});

  final AITriageResult? result;
  final Object? error;

  @override
  Future<AITriageResult> analyzeSymptoms(AITriageRequest request) async {
    if (error != null) throw error!;
    return result!;
  }
}

const _sampleResult = AITriageResult(
  summary: 'summary',
  urgency: AIUrgency.routine,
  recommendation: 'recommendation',
  reasoning: 'reasoning',
  redFlags: [],
  nextStep: 'next step',
  isUncertain: true,
  emergencyDetected: false,
);

void main() {
  group('AiCareController', () {
    test('starts idle', () {
      final controller = AiCareController(_FakeRepository(result: _sampleResult));
      expect(controller.state.status, AiCareStatus.idle);
    });

    test('does nothing for empty/whitespace-only symptoms (never reaches analyzing)', () async {
      final controller = AiCareController(_FakeRepository(result: _sampleResult));
      await controller.analyzeSymptoms(symptoms: '   ');
      expect(controller.state.status, AiCareStatus.idle);
    });

    test('transitions idle -> analyzing -> success on a successful call', () async {
      final controller = AiCareController(_FakeRepository(result: _sampleResult));

      final future = controller.analyzeSymptoms(symptoms: 'headache');
      expect(controller.state.status, AiCareStatus.analyzing);

      await future;
      expect(controller.state.status, AiCareStatus.success);
      expect(controller.state.result, _sampleResult);
      expect(controller.state.errorMessage, isNull);
    });

    test('transitions idle -> analyzing -> error on a failed call, with a safe message', () async {
      final controller = AiCareController(
        _FakeRepository(error: const AIServiceException(debugDetails: 'raw backend trace')),
      );

      final future = controller.analyzeSymptoms(symptoms: 'headache');
      expect(controller.state.status, AiCareStatus.analyzing);

      await future;
      expect(controller.state.status, AiCareStatus.error);
      expect(controller.state.errorMessage, 'Care guidance is temporarily unavailable.');
      // The raw debug detail must never leak into the user-facing message.
      expect(controller.state.errorMessage, isNot(contains('raw backend trace')));
    });

    test('reset() returns to idle and clears prior result/error', () async {
      final controller = AiCareController(_FakeRepository(result: _sampleResult));
      await controller.analyzeSymptoms(symptoms: 'headache');
      expect(controller.state.status, AiCareStatus.success);

      controller.reset();
      expect(controller.state.status, AiCareStatus.idle);
      expect(controller.state.result, isNull);
    });
  });
}
