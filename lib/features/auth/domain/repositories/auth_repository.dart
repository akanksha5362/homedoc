import '../../data/models/auth_requests.dart';
import '../../data/models/auth_token_response.dart';

abstract class AuthRepository {
  Future<AuthTokenResponse> register(RegisterRequest request);
  Future<AuthTokenResponse> login(LoginRequest request);
}
