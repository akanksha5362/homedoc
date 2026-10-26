import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/core/errors/app_exception.dart';
import 'package:homedoc/core/network/api_client.dart';
import 'package:homedoc/core/network/api_endpoints.dart';
import 'package:homedoc/features/ai_care/data/datasources/ai_care_remote_datasource.dart';
import 'package:homedoc/features/ai_care/data/models/ai_triage_request.dart';
import 'package:homedoc/features/ai_care/data/repositories/ai_care_repository_impl.dart';

/// A hand-written fake standing in for `ApiClient` — avoids needing
/// mocktail to fake a generic method with a function-typed parameter
/// (`parser`), which mocktail handles awkwardly. This still fully
/// exercises `AiCareRemoteDataSource`'s parsing/error logic, which is
/// the part actually under test here (the real HTTP behavior is already
/// covered by `error_mapper_test.dart`).
class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient({this.responseData, this.throwsError});

  final dynamic responseData;
  final Object? throwsError;

  @override
  Future<T> post<T>(String path, {dynamic data, required T Function(dynamic data) parser}) async {
    expect(path, ApiEndpoints.aiTriage);
    if (throwsError != null) throw throwsError!;
    return parser(responseData);
  }
}

void main() {
  const request = AITriageRequest(symptoms: 'headache and mild fever since yesterday');

  group('AiCareRemoteDataSource', () {
    test('parses a well-formed response into AITriageResult', () async {
      final client = _FakeApiClient(responseData: {
        'summary': 'Summary text',
        'urgency': 'routine',
        'recommendation': 'Recommendation text',
        'reasoning': 'Reasoning text',
        'red_flags': <String>[],
        'next_step': 'Next step text',
        'is_uncertain': true,
        'emergency_detected': false,
      });
      final dataSource = AiCareRemoteDataSource(client);

      final result = await dataSource.triage(request);

      expect(result.summary, 'Summary text');
      expect(result.emergencyDetected, isFalse);
    });

    test('throws AIServiceException when the response body is not a JSON object', () async {
      final client = _FakeApiClient(responseData: 'not an object');
      final dataSource = AiCareRemoteDataSource(client);

      expect(() => dataSource.triage(request), throwsA(isA<AIServiceException>()));
    });

    test('throws AIServiceException when the response is malformed (wrong field types)', () async {
      final client = _FakeApiClient(responseData: {'red_flags': 'not a list'});
      final dataSource = AiCareRemoteDataSource(client);

      expect(() => dataSource.triage(request), throwsA(isA<AIServiceException>()));
    });

    test('propagates an existing AppException from the underlying client unchanged', () async {
      final client = _FakeApiClient(throwsError: const RateLimitException());
      final dataSource = AiCareRemoteDataSource(client);

      expect(() => dataSource.triage(request), throwsA(isA<RateLimitException>()));
    });
  });

  group('AiCareRepositoryImpl', () {
    test('delegates to the data source and returns its result', () async {
      final client = _FakeApiClient(responseData: {
        'summary': 'S',
        'urgency': 'soon',
        'recommendation': 'R',
        'reasoning': 'Re',
        'red_flags': <String>[],
        'next_step': 'N',
        'is_uncertain': false,
        'emergency_detected': false,
      });
      final repository = AiCareRepositoryImpl(AiCareRemoteDataSource(client));

      final result = await repository.analyzeSymptoms(request);

      expect(result.summary, 'S');
    });

    test('propagates failure from the data source', () async {
      final client = _FakeApiClient(throwsError: const ServerException());
      final repository = AiCareRepositoryImpl(AiCareRemoteDataSource(client));

      expect(() => repository.analyzeSymptoms(request), throwsA(isA<ServerException>()));
    });
  });
}
