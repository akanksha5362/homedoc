import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/agent_response.dart';

class AiAssistantRemoteDataSource {
  AiAssistantRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AgentResponse> sendMessage(AgentRequest request) {
    return _apiClient.post<AgentResponse>(
      ApiEndpoints.aiAgent,
      data: request.toJson(),
      parser: (data) {
        try {
          if (data is! Map) {
            throw const AIServiceException(
              debugDetails: 'AI agent response was not a JSON object.',
            );
          }

          final json = Map<String, dynamic>.from(data);

          return AgentResponse.fromJson(json);
        } on AIServiceException {
          rethrow;
        } catch (error) {
          throw AIServiceException(
            debugDetails: 'Unable to parse AI agent response: $error',
          );
        }
      },
    );
  }
}