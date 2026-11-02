
import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../errors/error_mapper.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

// The ONLY class in the app permitted to make HTTP calls.
//
// Enforced boundary:
//   UI -> Provider/Controller -> Repository -> ApiClient -> FastAPI
//
// Widgets and providers must never import dio directly.
// They depend on a feature Repository, which depends on this client.
// This keeps HTTP concerns (auth headers, retries, error mapping,
// logging) in one place and makes repositories trivially mockable.

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureStorageService secureStorage,
  })  : _config = config,
        _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        // Use the configured API base URL.
        // Android emulator: http://10.0.2.2:8000
        // iOS Simulator/Desktop: http://localhost:8000
        // Override using --dart-define=API_BASE_URL=...
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_secureStorage));

    if (_config.enableVerboseLogging) {
      // Development-only logging.
      // Never enabled in production builds.
      // The interceptor logs method/path/status only and does not
      // log request or response bodies.
      _dio.interceptors.add(_SafeLoggingInterceptor());
    }
  }

  final AppConfig _config;
  final SecureStorageService _secureStorage;

  late final Dio _dio;

  Future<T> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        required T Function(dynamic data) parser,
      }) =>
      _request(
            () => _dio.get(
          path,
          queryParameters: queryParameters,
        ),
        parser,
      );

  Future<T> post<T>(
      String path, {
        dynamic data,
        required T Function(dynamic data) parser,
      }) =>
      _request(
            () => _dio.post(
          path,
          data: data,
        ),
        parser,
      );

  Future<T> patch<T>(
      String path, {
        dynamic data,
        required T Function(dynamic data) parser,
      }) =>
      _request(
            () => _dio.patch(
          path,
          data: data,
        ),
        parser,
      );

  Future<T> delete<T>(
      String path, {
        required T Function(dynamic data) parser,
      }) =>
      _request(
            () => _dio.delete(path),
        parser,
      );

  Future<T> _request<T>(
      Future<Response<dynamic>> Function() call,
      T Function(dynamic data) parser,
      ) async {
    try {
      final response = await call();
      return parser(response.data);
    } catch (error, stackTrace) {
      // Every failure is normalized here so nothing above this layer
      // ever has to know what Dio or the backend actually returned.
      throw ErrorMapper.map(error, stackTrace);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._secureStorage);

  final SecureStorageService _secureStorage;

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _secureStorage.readAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}

// Logs method/path/status only.
// Request/response bodies are NEVER logged wholesale since they may
// contain medical data, tokens, or payment details.

class _SafeLoggingInterceptor extends Interceptor {
  final _log = AppLogger('API');

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    _log.debug('-> ${options.method}${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    _log.debug(
      '<- ${response.statusCode}${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) {
    _log.warning(
      '<- ERROR ${err.response?.statusCode} '
          '${err.requestOptions.path}:${err.type}',
    );
    handler.next(err);
  }
}
