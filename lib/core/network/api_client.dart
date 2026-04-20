import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:logger/logger.dart';
import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/network/auth_interceptor.dart';
import 'package:voyanz/core/storage/token_storage.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Singleton-style factory that returns a configured [Dio] instance.
class ApiClient {
  ApiClient._();

  static Dio? _instance;
  static CookieJar? _cookieJar;

  static Dio create(TokenStorage tokenStorage) {
    if (_instance != null) {
      _sanitizeExistingClient(_instance!);
      return _instance!;
    }

    _cookieJar = CookieJar();

    _instance = Dio(
      BaseOptions(
        baseUrl: EnvConfig.current.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (EnvConfig.current.apiKey != null) ...{
            // Some deployments still read legacy `ApiKey` while newer ones use `x-api-key`.
            'x-api-key': EnvConfig.current.apiKey,
            'ApiKey': EnvConfig.current.apiKey,
          },
        },
      ),
    );

    _instance!.interceptors.add(_MobileApiHeadersInterceptor());
    _instance!.interceptors.add(CookieManager(_cookieJar!));
    _instance!.interceptors.add(AuthInterceptor(tokenStorage));

    _logger.i(
      'ApiClient initialized: baseUrl=${EnvConfig.current.baseUrl}, '
      'environment=${EnvConfig.current.environment.name}, '
      'apiKey=${EnvConfig.current.apiKey == null ? "missing" : "present"}, '
      'mockBackend=$kUseMockBackend',
    );

    // Keep logs light in mock mode to avoid noisy output and extra work.
    if (!kUseMockBackend) {
      _instance!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => _logger.d(obj),
        ),
      );
    }

    return _instance!;
  }

  static void _sanitizeExistingClient(Dio dio) {
    final apiKey = EnvConfig.current.apiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      dio.options.headers['x-api-key'] = apiKey;
      dio.options.headers['ApiKey'] = apiKey;
    }

    // Remove stale CSRF interceptors/headers that may survive hot reload.
    dio.interceptors.removeWhere(
      (interceptor) => interceptor.runtimeType.toString().contains('Csrf'),
    );
    if (!dio.interceptors.any((i) => i is _MobileApiHeadersInterceptor)) {
      dio.interceptors.insert(0, _MobileApiHeadersInterceptor());
    }
  }

  /// Reset for testing or environment switch.
  static void reset() {
    _instance = null;
    _cookieJar = null;
  }
}

class _MobileApiHeadersInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = EnvConfig.current.apiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers['x-api-key'] = apiKey;
      options.headers['ApiKey'] = apiKey;
    }

    // Mobile API must not send CSRF headers.
    options.headers.remove('X-CSRF-Token');
    options.headers.remove('x-csrf-token');
    options.headers.remove('X-XSRF-TOKEN');
    options.headers.remove('x-xsrf-token');

    handler.next(options);
  }
}
