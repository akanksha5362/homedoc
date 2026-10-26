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
          if (data is! Map<String, dynamic>) {
            throw const AIServiceException(debugDetails: 'Non-object agent response body');
          }
          return AgentResponse.fromJson(data);
        } on AIServiceException {
          rethrow;
        } catch (e) {
          throw AIServiceException(debugDetails: 'Malformed agent response: $e');
        }
      },
    );
  }
}
