import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../data/models/agent_response.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../data/datasources/gemini_ai_datasource.dart';

enum AiAssistantStatus {
  idle,
  sending,
  error,
}

/// A single conversation turn shown in the UI.
///
/// The actual conversation memory is handled by the backend using
/// the session ID. This class only stores the turns needed for display.
class AiAssistantTurn {
  const AiAssistantTurn({
    required this.userMessage,
    this.response,
  });

  final String userMessage;

  /// Null while the request is still in progress.
  final AgentResponse? response;
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
  AiAssistantController(this._repository)
      : super(const AiAssistantState());

  final AiAssistantRepository _repository;

  /// Identifies the active request.
  ///
  /// Incrementing this value invalidates an older request, for example
  /// when the user starts a new conversation before it finishes.
  int _requestVersion = 0;

  Future<void> sendMessage(String message) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) return;

    // Prevent duplicate requests while one is already in progress.
    if (state.isSending) return;

    final requestVersion = ++_requestVersion;

    final pendingTurns = [
      ...state.turns,
      AiAssistantTurn(userMessage: trimmedMessage),
    ];

    state = state.copyWith(
      status: AiAssistantStatus.sending,
      turns: pendingTurns,
    );

    try {
      final response = await _repository.sendMessage(
        AgentRequest(
          message: trimmedMessage,
          sessionId: state.sessionId,
        ),
      );

      // Ignore results from a request that has since been invalidated.
      if (requestVersion != _requestVersion) return;

      final completedTurns = [
        ...pendingTurns.take(pendingTurns.length - 1),
        AiAssistantTurn(
          userMessage: trimmedMessage,
          response: response,
        ),
      ];

      state = state.copyWith(
        status: AiAssistantStatus.idle,
        turns: completedTurns,
        sessionId: response.sessionId,
      );
    } catch (error) {
      // Ignore errors from requests that are no longer active.
      if (requestVersion != _requestVersion) return;

      final appException =
      error is AppException ? error : ErrorMapper.map(error);

      // Remove the unfinished turn. The page can offer a retry.
      final completedTurns = pendingTurns
          .take(pendingTurns.length - 1)
          .toList();

      state = state.copyWith(
        status: AiAssistantStatus.error,
        turns: completedTurns,
        errorMessage: appException.message,
      );
    }
  }

  /// Starts a fresh conversation in the UI.
  ///
  /// The next request will not reuse the previous session ID.
  void reset() {
    // Invalidate any request that is still in flight.
    _requestVersion++;

    state = const AiAssistantState();
  }
}

final aiAssistantRepositoryProvider =
Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(
    GeminiAiDataSource(),
  );
});

final aiAssistantControllerProvider =
StateNotifierProvider<AiAssistantController, AiAssistantState>(
      (ref) {
    return AiAssistantController(
      ref.watch(aiAssistantRepositoryProvider),
    );
  },
);