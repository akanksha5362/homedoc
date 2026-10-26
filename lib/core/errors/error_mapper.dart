import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Single place responsible for turning a raw [DioException] (or anything
/// else that escapes the API client) into a safe, user-facing
/// [AppException]. No other layer should inspect status codes directly —
/// this keeps that logic in one testable place (Day 3 §9: "never expose
/// raw stack traces or technical server errors to users").
class ErrorMapper {
  const ErrorMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _mapDioException(error);
    }

    return UnknownAppException(debugDetails: error.toString());
  }

  static AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutAppException(debugDetails: e.message);
      case DioExceptionType.connectionError:
        return NetworkException(debugDetails: e.message);
      case DioExceptionType.cancel:
        return const UnknownAppException(debugDetails: 'Request cancelled');
      case DioExceptionType.badResponse:
        return _mapStatusCode(e);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownAppException(debugDetails: e.message);
    }
  }

  static AppException _mapStatusCode(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    switch (status) {
      case 400:
        return ValidationException(
          _extractMessage(body) ?? 'Please check the information you entered.',
          fieldErrors: _extractFieldErrors(body),
          debugDetails: body?.toString(),
        );
      case 401:
        return AuthenticationException(debugDetails: body?.toString());
      case 403:
        return AuthorizationException(debugDetails: body?.toString());
      case 404:
        return NotFoundException(debugDetails: body?.toString());
      case 422:
        return ValidationException(
          _extractMessage(body) ?? 'Some information is missing or invalid.',
          fieldErrors: _extractFieldErrors(body),
          debugDetails: body?.toString(),
        );
      case 429:
        return RateLimitException(debugDetails: body?.toString());
      case 502:
      case 503:
      case 504:
        return _isAiEndpoint(e) ? AIServiceException(debugDetails: body?.toString()) : ServerException(debugDetails: body?.toString());
      default:
        if (status != null && status >= 500) {
          return _isAiEndpoint(e)
              ? AIServiceException(debugDetails: body?.toString())
              : ServerException(debugDetails: body?.toString());
        }
        return UnknownAppException(debugDetails: 'HTTP $status: ${body?.toString()}');
    }
  }

  /// Distinguishes AI Gateway failures from generic backend failures purely
  /// by request path — no other layer needs to know this distinction
  /// exists (Day 3 §9: status-code inspection stays in this one file).
  static bool _isAiEndpoint(DioException e) => e.requestOptions.path.startsWith('/ai/');

  static String? _extractMessage(dynamic body) {
    if (body is Map && body['message'] is String) return body['message'] as String;
    if (body is Map && body['detail'] is String) return body['detail'] as String;
    return null;
  }

  static Map<String, String>? _extractFieldErrors(dynamic body) {
    if (body is Map && body['errors'] is Map) {
      return (body['errors'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    return null;
  }
}
