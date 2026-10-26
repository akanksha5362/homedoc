import '../../domain/repositories/ai_care_repository.dart';
import '../datasources/ai_care_remote_datasource.dart';
import '../models/ai_triage_request.dart';
import '../models/ai_triage_result.dart';

class AiCareRepositoryImpl implements AiCareRepository {
  AiCareRepositoryImpl(this._remote);

  final AiCareRemoteDataSource _remote;

  @override
  Future<AITriageResult> analyzeSymptoms(AITriageRequest request) => _remote.triage(request);
}
