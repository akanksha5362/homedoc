import 'dart:io' show Platform;

import 'environment.dart';

/// -----------------------------------------------------------------------
/// SECURITY BOUNDARY — READ BEFORE ADDING ANYTHING HERE
/// -----------------------------------------------------------------------
/// Safe to expose in Flutter (compiled into the client, visible to anyone
/// who decompiles the app):
///   - Backend API base URL
///   - Public feature flags
///   - Non-secret third-party *public* keys (e.g. a Maps SDK key restricted
///     by platform/package-name/bundle-id at the provider console)
///
/// MUST remain server-side only (FastAPI / secret manager), NEVER placed
/// here or anywhere in this repository:
///   - Gemini / Vertex AI API keys           -> AI Gateway only (Day 1 §31)
///   - Razorpay secret key                   -> FastAPI payment service only
///   - Database credentials
///   - Any signing keys / webhook secrets
///
/// The Flutter app talks to FastAPI; FastAPI talks to Gemini/Razorpay/DB.
/// See core/network/api_client.dart and the "AI Architecture Rule" /
/// "Payment Architecture Rule" sections of the Day 3 prompt.
/// -----------------------------------------------------------------------
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableVerboseLogging,
  });

  final Environment environment;
  final String apiBaseUrl;
  final bool enableVerboseLogging;

  factory AppConfig.forEnvironment(Environment env) {
    switch (env) {
      case Environment.production:
        return const AppConfig(
          environment: Environment.production,
          apiBaseUrl: 'https://api.homedoc.ai', // placeholder — real domain TBD
          enableVerboseLogging: false,
        );
      case Environment.staging:
        return const AppConfig(
          environment: Environment.staging,
          apiBaseUrl: 'https://staging-api.homedoc.ai', // placeholder
          enableVerboseLogging: true,
        );
      case Environment.development:
        return AppConfig(
          environment: Environment.development,
          apiBaseUrl: _developmentBaseUrl(),
          enableVerboseLogging: true,
        );
    }
  }

  bool get isProduction => environment == Environment.production;

  /// FIXED (Day 4 §13): this previously hardcoded `http://localhost:8000`
  /// for every development run. That's correct for iOS Simulator/desktop,
  /// but `localhost` inside an Android emulator refers to the emulator
  /// itself, not the host Mac/PC running the backend — every request
  /// would silently fail to connect. Android's documented loopback alias
  /// for the host machine is `10.0.2.2`.
  ///
  /// Resolution order:
  ///   1. Explicit override — `flutter run --dart-define=API_BASE_URL=...`
  ///      (needed for a physical device on the same LAN, where neither
  ///      `localhost` nor `10.0.2.2` reaches the host machine).
  ///   2. Platform-detected default: Android emulator -> 10.0.2.2,
  ///      everything else (iOS Simulator, macOS/Linux/Windows desktop) ->
  ///      localhost.
  static String _developmentBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
