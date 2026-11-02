import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/gemini_ai_datasource.dart';
import '../models/agent_response.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._gemini);

  final GeminiAiDataSource _gemini;

  @override
  Future<AgentResponse> sendMessage(AgentRequest request) {
    return _gemini.sendMessage(request);
  }
}