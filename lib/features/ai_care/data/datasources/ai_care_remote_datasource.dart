import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ai_triage_request.dart';
import '../models/ai_triage_result.dart';
import '../models/conversational_triage_request.dart';

/// Talks to `ApiClient` only — never `dio` directly (Day 3 §8/§17).
/// This is the only file that knows the `/ai/triage` JSON shape; the
/// repository above it works entirely in domain/data model terms.
class AiCareRemoteDataSource {
  AiCareRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AITriageResult> triage(AITriageRequest request) {
    return _apiClient.post<AITriageResult>(
      ApiEndpoints.aiTriage,
      data: request.toJson(),
      parser: _parseTriageResult,
    );
  }

  Future<AITriageResult> conversationalTriage(
      ConversationalTriageRequest request,
      ) {
    return _apiClient.post<AITriageResult>(
      ApiEndpoints.aiConversationalTriage,
      data: request.toJson(),
      parser: _parseConversationalTriageResult,
    );
  }

  AITriageResult _parseTriageResult(dynamic data) {
    // A malformed/unexpected AI Gateway response must never crash the
    // app or silently show garbage — it becomes the same
    // AIServiceException the UI already knows how to render
    // (Day 3 AI prompt, Step 15: "malformed AI response").
    try {
      if (data is! Map<String, dynamic>) {
        throw const AIServiceException(
          debugDetails: 'Non-object AI response body',
        );
      }
      return AITriageResult.fromJson(data);
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException(debugDetails: 'Malformed AI response: $e');
    }
  }

  AITriageResult _parseConversationalTriageResult(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const AIServiceException(
        debugDetails: 'Non-object conversational triage response body',
      );
    }

    const requiredTextFields = [
      'summary',
      'urgency',
      'why_assigned',
      'recommendation',
      'next_step',
      'disclaimer',
    ];
    for (final field in requiredTextFields) {
      if (data[field] is! String || (data[field] as String).trim().isEmpty) {
        throw AIServiceException(
          debugDetails: 'Missing or empty conversational triage field: $field',
        );
      }
    }
    if (data['is_uncertain'] is! bool ||
        data['emergency_detected'] is! bool ||
        data['red_flags'] is! List ||
        !(data['red_flags'] as List).every((item) => item is String)) {
      throw const AIServiceException(
        debugDetails:
        'Conversational triage response is missing typed safety fields',
      );
    }
    try {
      return AITriageResult.fromJson(data);
    } catch (error) {
      throw AIServiceException(
        debugDetails: 'Malformed conversational triage response: $error',
      );
    }
  }
}
