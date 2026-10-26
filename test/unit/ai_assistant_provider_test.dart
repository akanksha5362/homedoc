import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/core/errors/app_exception.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_response.dart';
import 'package:homedoc/features/ai_assistant/data/models/agent_risk_level.dart';
import 'package:homedoc/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:homedoc/features/ai_assistant/presentation/providers/ai_assistant_provider.dart';

class _FakeRepository implements AiAssistantRepository {
  _FakeRepository({this.response, this.error});

  AgentResponse? response;
  Object? error;
  AgentRequest? lastRequest;

  @override
  Future<AgentResponse> sendMessage(AgentRequest request) async {
    lastRequest = request;
    if (error != null) throw error!;
    return response!;
  }
}

AgentResponse _doctorSearchResponse({String sessionId = 'session-1'}) => AgentResponse(
      message: 'Found some doctors.',
      intent: 'doctor_search',
      riskLevel: AgentRiskLevel.low,
      requiresConfirmation: false,
      actions: const [],
      sessionId: sessionId,
    );

void main() {
  group('AiAssistantController', () {
    test('starts idle with no turns', () {
      final controller = AiAssistantController(_FakeRepository());
      expect(controller.state.status, AiAssistantStatus.idle);
      expect(controller.state.turns, isEmpty);
    });

    test('ignores empty/whitespace-only messages', () async {
      final controller = AiAssistantController(_FakeRepository());
      await controller.sendMessage('   ');
      expect(controller.state.turns, isEmpty);
    });

    test('adds a pending turn immediately, then fills in the response on success', () async {
      final repo = _FakeRepository(response: _doctorSearchResponse());
      final controller = AiAssistantController(repo);

      final future = controller.sendMessage('find a doctor');
      expect(controller.state.status, AiAssistantStatus.sending);
      expect(controller.state.turns, hasLength(1));
      expect(controller.state.turns.first.response, isNull);

      await future;

      expect(controller.state.status, AiAssistantStatus.idle);
      expect(controller.state.turns, hasLength(1));
      expect(controller.state.turns.first.response, isNotNull);
    });

    test('REGRESSION: persists the session_id returned by the backend for the next turn', () async {
      final repo = _FakeRepository(response: _doctorSearchResponse(sessionId: 'server-issued-session'));
      final controller = AiAssistantController(repo);

      await controller.sendMessage('find a doctor');

      expect(controller.state.sessionId, 'server-issued-session');

      // The next call must send that session id back, not omit it.
      await controller.sendMessage('and one that does video too');
      expect(repo.lastRequest!.sessionId, 'server-issued-session');
    });

    test('on failure, removes the pending turn and surfaces a safe error message', () async {
      final repo = _FakeRepository(error: const AIServiceException());
      final controller = AiAssistantController(repo);

      await controller.sendMessage('find a doctor');

      expect(controller.state.status, AiAssistantStatus.error);
      expect(controller.state.turns, isEmpty);
      expect(controller.state.errorMessage, 'Care guidance is temporarily unavailable.');
    });

    test('reset() clears turns and session', () async {
      final repo = _FakeRepository(response: _doctorSearchResponse());
      final controller = AiAssistantController(repo);
      await controller.sendMessage('find a doctor');

      controller.reset();

      expect(controller.state.turns, isEmpty);
      expect(controller.state.sessionId, isNull);
      expect(controller.state.status, AiAssistantStatus.idle);
    });
  });
}
