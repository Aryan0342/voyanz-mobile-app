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
    if (_instance != null) return _instance!;

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

    _instance!.interceptors.add(CookieManager(_cookieJar!));
    _instance!.interceptors.add(_CsrfHeaderInterceptor(_cookieJar!));
    _instance!.interceptors.add(AuthInterceptor(tokenStorage));

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

  /// Reset for testing or environment switch.
  static void reset() {
    _instance = null;
    _cookieJar = null;
  }
}

class _CsrfHeaderInterceptor extends Interceptor {
  final CookieJar _cookieJar;

  _CsrfHeaderInterceptor(this._cookieJar);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final cookies = await _cookieJar.loadForRequest(options.uri);
    final csrfToken = _extractCsrfToken(cookies);
    if (csrfToken != null && csrfToken.isNotEmpty) {
      options.headers['X-CSRF-Token'] = csrfToken;
      options.headers['X-XSRF-TOKEN'] = csrfToken;
    }
    handler.next(options);
  }

  String? _extractCsrfToken(List<Cookie> cookies) {
    for (final cookie in cookies) {
      final name = cookie.name.toLowerCase();
      if (name == 'xsrf-token' ||
          name == 'csrf-token' ||
          name == 'csrf_token' ||
          name == '_csrf') {
        return cookie.value;
      }
    }
    return null;
  }
}
