import '../../data/models/agent_response.dart';

abstract class AiAssistantRepository {
  Future<AgentResponse> sendMessage(AgentRequest request);
}
