import '../../data/models/ai_triage_request.dart';
import '../../data/models/ai_triage_result.dart';

/// Domain contract for the AI Care feature. The presentation layer depends
/// on this interface, not on `AiCareRepositoryImpl` directly — makes the
/// provider trivially testable with a fake/mock repository (see
/// test/unit/ai_care_provider_test.dart).
abstract class AiCareRepository {
  Future<AITriageResult> analyzeSymptoms(AITriageRequest request);
}
