import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_requests.dart';
import '../models/auth_token_response.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokenResponse> register(RegisterRequest request) {
    return _apiClient.post<AuthTokenResponse>(
      ApiEndpoints.register,
      data: request.toJson(),
      parser: (data) => AuthTokenResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthTokenResponse> login(LoginRequest request) {
    return _apiClient.post<AuthTokenResponse>(
      ApiEndpoints.login,
      data: request.toJson(),
      parser: (data) => AuthTokenResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
