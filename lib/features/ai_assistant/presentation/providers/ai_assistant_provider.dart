import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/providers/auth_provider.dart' show apiClientProvider;
import '../../data/datasources/ai_assistant_remote_datasource.dart';
import '../../data/models/agent_response.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

enum AiAssistantStatus { idle, sending, error }

/// A single turn in the assistant conversation, for rendering purposes
/// only — the actual conversation memory lives server-side (backend
/// app/ai/agent/memory.py), keyed by [sessionId]. This is just what the
/// UI shows, not a second source of truth.
class AiAssistantTurn {
  const AiAssistantTurn({required this.userMessage, this.response});

  final String userMessage;
  final AgentResponse? response; // null while this turn's request is in flight
}

class AiAssistantState {
  const AiAssistantState({
    this.status = AiAssistantStatus.idle,
    this.turns = const [],
    this.sessionId,
    this.errorMessage,
  });

  final AiAssistantStatus status;
  final List<AiAssistantTurn> turns;
  final String? sessionId;
  final String? errorMessage;

  bool get isSending => status == AiAssistantStatus.sending;

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    List<AiAssistantTurn>? turns,
    String? sessionId,
    String? errorMessage,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      turns: turns ?? this.turns,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage,
    );
  }
}

class AiAssistantController extends StateNotifier<AiAssistantState> {
  AiAssistantController(this._repository) : super(const AiAssistantState());

  final AiAssistantRepository _repository;

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final pendingTurns = [...state.turns, AiAssistantTurn(userMessage: trimmed)];
    state = state.copyWith(status: AiAssistantStatus.sending, turns: pendingTurns);

    try {
      final response = await _repository.sendMessage(
        AgentRequest(message: trimmed, sessionId: state.sessionId),
      );
      final updatedTurns = [...pendingTurns]
        ..removeLast()
        ..add(AiAssistantTurn(userMessage: trimmed, response: response));
      state = state.copyWith(
        status: AiAssistantStatus.idle,
        turns: updatedTurns,
        sessionId: response.sessionId,
      );
    } catch (error) {
      final appException = error is AppException ? error : ErrorMapper.map(error);
      final updatedTurns = [...pendingTurns]..removeLast();
      state = state.copyWith(
        status: AiAssistantStatus.error,
        turns: updatedTurns,
        errorMessage: appException.message,
      );
    }
  }

  void reset() => state = const AiAssistantState();
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(AiAssistantRemoteDataSource(ref.watch(apiClientProvider)));
});

final aiAssistantControllerProvider =
    StateNotifierProvider<AiAssistantController, AiAssistantState>((ref) {
  return AiAssistantController(ref.watch(aiAssistantRepositoryProvider));
});
