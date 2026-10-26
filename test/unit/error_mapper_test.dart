import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/core/errors/app_exception.dart';
import 'package:homedoc/core/errors/error_mapper.dart';

RequestOptions _opts() => RequestOptions(path: '/test');

void main() {
  group('ErrorMapper', () {
    test('maps connection timeout to TimeoutAppException', () {
      final e = DioException(requestOptions: _opts(), type: DioExceptionType.connectionTimeout);
      expect(ErrorMapper.map(e), isA<TimeoutAppException>());
    });

    test('maps connection error to NetworkException', () {
      final e = DioException(requestOptions: _opts(), type: DioExceptionType.connectionError);
      expect(ErrorMapper.map(e), isA<NetworkException>());
    });

    test('maps HTTP 401 to AuthenticationException', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: _opts(), statusCode: 401),
      );
      expect(ErrorMapper.map(e), isA<AuthenticationException>());
    });

    test('maps HTTP 403 to AuthorizationException', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: _opts(), statusCode: 403),
      );
      expect(ErrorMapper.map(e), isA<AuthorizationException>());
    });

    test('maps HTTP 404 to NotFoundException', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: _opts(), statusCode: 404),
      );
      expect(ErrorMapper.map(e), isA<NotFoundException>());
    });

    test('maps HTTP 429 to RateLimitException', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: _opts(), statusCode: 429),
      );
      expect(ErrorMapper.map(e), isA<RateLimitException>());
    });

    test('maps HTTP 500+ to ServerException', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: _opts(), statusCode: 503),
      );
      expect(ErrorMapper.map(e), isA<ServerException>());
    });

    test('passes through an existing AppException unchanged', () {
      const original = ValidationException('bad input');
      expect(ErrorMapper.map(original), same(original));
    });

    test('never exposes raw error text in the user-facing message', () {
      final e = DioException(
        requestOptions: _opts(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: _opts(),
          statusCode: 500,
          data: {'trace': 'Traceback (most recent call last): ...'},
        ),
      );
      final mapped = ErrorMapper.map(e);
      expect(mapped.message, isNot(contains('Traceback')));
    });
  });
}
