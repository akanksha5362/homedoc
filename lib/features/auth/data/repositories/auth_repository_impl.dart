import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_requests.dart';
import '../models/auth_token_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AuthTokenResponse> register(RegisterRequest request) => _remote.register(request);

  @override
  Future<AuthTokenResponse> login(LoginRequest request) => _remote.login(request);
}
