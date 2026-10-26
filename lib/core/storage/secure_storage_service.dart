import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps platform secure storage (Keychain on iOS, Keystore-backed on
/// Android). Scope is intentionally narrow: authentication tokens + the
/// minimal identity fields needed to restore a session (see below) — never
/// medical data.
///
/// Medical records, prescriptions, and reports are NEVER cached here or in
/// any local persistence layer at foundation stage — they're fetched live
/// from the authenticated API per screen. If offline caching of non-
/// sensitive data (e.g. an appointment summary) is added later per Day 1
/// §44, it must go through a separate, explicitly-reviewed cache — not
/// this class.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'homedoc.access_token';
  static const _refreshTokenKey = 'homedoc.refresh_token';
  static const _roleKey = 'homedoc.role';
  static const _userIdKey = 'homedoc.user_id';
  static const _displayNameKey = 'homedoc.display_name';

  /// [refreshToken] is optional (Day 4 §14 finding): the real backend's
  /// `TokenResponse` (backend/app/schemas/auth.py) only issues an
  /// `access_token` — there is no refresh-token flow yet (documented as a
  /// known limitation in backend/README.md). This was previously a
  /// required parameter, which would have made real login impossible to
  /// wire up without inventing a refresh token the backend doesn't send.
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// The real backend has no `/patients/me`-style endpoint yet (see
  /// backend/README.md's tool/endpoint inventory) — there is nothing to
  /// call to rehydrate the signed-in user's role/name after an app
  /// restart. Until that endpoint exists, the minimal identity fields
  /// returned at login/register time are cached here so session
  /// restoration doesn't have to fall back to a fabricated mock user.
  Future<void> saveIdentity({required String userId, required String role, String? displayName}) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
    if (displayName != null) {
      await _storage.write(key: _displayNameKey, value: displayName);
    }
  }

  Future<String?> readUserId() => _storage.read(key: _userIdKey);
  Future<String?> readRole() => _storage.read(key: _roleKey);
  Future<String?> readDisplayName() => _storage.read(key: _displayNameKey);

  /// Called on logout and on unrecoverable auth failure (Day 3 §22 —
  /// "logout cleanup").
  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _displayNameKey);
  }
}
