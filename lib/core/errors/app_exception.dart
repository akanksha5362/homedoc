/// Standardized error taxonomy (Day 3, Section 9). Every layer above the
/// API client (repositories, providers, UI) should only ever see one of
/// these — never a raw [DioException] or backend stack trace.
sealed class AppException implements Exception {
  const AppException(this.message, {this.debugDetails});

  /// User-facing, already-safe-to-display message.
  final String message;

  /// Developer-only detail (logged, never rendered to the user).
  final String? debugDetails;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException({super.debugDetails})
      : super("We couldn't reach HomeDoc AI. Please check your connection.");
}

class TimeoutAppException extends AppException {
  const TimeoutAppException({super.debugDetails})
      : super('That took longer than expected. Please try again.');
}

class AuthenticationException extends AppException {
  const AuthenticationException({super.debugDetails})
      : super('Your session has expired. Please sign in again.');
}

class AuthorizationException extends AppException {
  const AuthorizationException({super.debugDetails})
      : super("You don't have permission to do that.");
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors, super.debugDetails});
  final Map<String, String>? fieldErrors;
}

class NotFoundException extends AppException {
  const NotFoundException({super.debugDetails})
      : super("We couldn't find what you were looking for.");
}

class ServerException extends AppException {
  const ServerException({super.debugDetails})
      : super("We couldn't load this right now.");
}

class RateLimitException extends AppException {
  const RateLimitException({super.debugDetails})
      : super("You've made too many requests. Please wait a moment and try again.");
}

/// Errors surfaced by the backend's AI Gateway (Day 1 §31) — kept distinct
/// from ServerException so the UI can show AI-specific fallback copy
/// ("Care guidance is temporarily unavailable...") per UX/UI Architecture
/// v1 §6.
class AIServiceException extends AppException {
  const AIServiceException({super.debugDetails})
      : super('Care guidance is temporarily unavailable.');
}

class PaymentException extends AppException {
  const PaymentException(super.message, {super.debugDetails});
}

class LocationException extends AppException {
  const LocationException(super.message, {super.debugDetails});
}

class UnknownAppException extends AppException {
  const UnknownAppException({super.debugDetails})
      : super('Something unexpected happened. Please try again.');
}
