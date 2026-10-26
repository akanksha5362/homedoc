import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_assistant_remote_datasource.dart';
import '../models/agent_response.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._remote);

  final AiAssistantRemoteDataSource _remote;

  @override
  Future<AgentResponse> sendMessage(AgentRequest request) => _remote.sendMessage(request);
}
