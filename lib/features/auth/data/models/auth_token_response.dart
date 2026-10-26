import 'package:equatable/equatable.dart';
import '../../../../shared/models/user_model.dart';

/// Mirrors backend/app/schemas/auth.py TokenResponse exactly:
/// {access_token, token_type, role, user_id}. Note there is deliberately
/// no `display_name` field here — the backend doesn't return one (see
/// SecureStorageService's saveIdentity note) — the client supplies it
/// separately from what the user typed at registration, or falls back to
/// a generic label at login.
class AuthTokenResponse extends Equatable {
  const AuthTokenResponse({
    required this.accessToken,
    required this.role,
    required this.userId,
  });

  final String accessToken;
  final UserRole role;
  final String userId;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) => AuthTokenResponse(
        accessToken: json['access_token'] as String,
        role: UserRole.values.byName(json['role'] as String),
        userId: json['user_id'] as String,
      );

  @override
  List<Object?> get props => [accessToken, role, userId];
}
