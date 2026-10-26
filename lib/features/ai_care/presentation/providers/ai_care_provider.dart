import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/providers/auth_provider.dart' show apiClientProvider;
import '../../data/datasources/ai_care_remote_datasource.dart';
import '../../data/models/ai_triage_request.dart';
import '../../data/models/ai_triage_result.dart';
import '../../data/repositories/ai_care_repository_impl.dart';
import '../../domain/repositories/ai_care_repository.dart';

/// Day 3 AI prompt, Step 7: idle / analyzing / success / error.
enum AiCareStatus { idle, analyzing, success, error }

class AiCareState {
  const AiCareState({this.status = AiCareStatus.idle, this.result, this.errorMessage});

  final AiCareStatus status;
  final AITriageResult? result;

  /// Already-safe-to-display message from [AppException.message] — never
  /// a raw error (Day 3 §9, carried into this feature unchanged).
  final String? errorMessage;

  bool get isAnalyzing => status == AiCareStatus.analyzing;

  AiCareState copyWith({AiCareStatus? status, AITriageResult? result, String? errorMessage}) {
    return AiCareState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

class AiCareController extends StateNotifier<AiCareState> {
  AiCareController(this._repository) : super(const AiCareState());

  final AiCareRepository _repository;

  Future<void> analyzeSymptoms({
    required String symptoms,
    String? duration,
    String? additionalContext,
  }) async {
    if (symptoms.trim().isEmpty) return;

    state = const AiCareState(status: AiCareStatus.analyzing);

    try {
      final result = await _repository.analyzeSymptoms(
        AITriageRequest(symptoms: symptoms.trim(), duration: duration, additionalContext: additionalContext),
      );
      state = AiCareState(status: AiCareStatus.success, result: result);
    } catch (error) {
      // Never logs `symptoms`/`error` bodies (Day 3 AI prompt, Step 14) —
      // only the already-mapped, already-safe AppException.message reaches
      // state, and nothing here calls a logger with the raw payload.
      final appException = error is AppException ? error : ErrorMapper.map(error);
      state = AiCareState(status: AiCareStatus.error, errorMessage: appException.message);
    }
  }

  void reset() => state = const AiCareState();
}

final aiCareRepositoryProvider = Provider<AiCareRepository>((ref) {
  return AiCareRepositoryImpl(AiCareRemoteDataSource(ref.watch(apiClientProvider)));
});

final aiCareControllerProvider = StateNotifierProvider<AiCareController, AiCareState>((ref) {
  return AiCareController(ref.watch(aiCareRepositoryProvider));
});
