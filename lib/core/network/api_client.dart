import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/network/account_requirement_interceptor.dart';
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

    if (!kIsWeb) {
      _cookieJar = CookieJar();
    }

    _instance = Dio(
      BaseOptions(
        baseUrl: EnvConfig.current.baseUrl,
        connectTimeout: const Duration(seconds: 300),
        receiveTimeout: const Duration(seconds: 300),
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
    // Browsers manage cookies themselves. dio_cookie_manager intentionally
    // asserts on web, so only install it for the native iOS/Android clients.
    if (!kIsWeb) {
      _instance!.interceptors.add(CookieManager(_cookieJar!));
    }
    _instance!.interceptors.add(AuthInterceptor(tokenStorage));
    _instance!.interceptors.add(AccountRequirementInterceptor());

    _logger.i(
      'ApiClient initialized: baseUrl=${EnvConfig.current.baseUrl}, '
      'environment=${EnvConfig.current.environment.name}, '
      'apiKey=${EnvConfig.current.apiKey == null ? "missing" : "present"}, '
      'mockBackend=$kUseMockBackend',
    );

    // Debug builds only: a release build must never write request bodies to
    // the device log, because the login body carries the plain-text password
    // and the response carries the access and refresh tokens. Even in debug
    // the known secrets are masked, so a shared log or a bug report cannot
    // leak a usable credential.
    if (!kUseMockBackend && kDebugMode) {
      _instance!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[DIO] ${_redactSecrets('$obj')}'),
        ),
      );
    }

    return _instance!;
  }

  @visibleForTesting
  static String redactForTesting(String line) => _redactSecrets(line);

  /// Masks credentials in a log line: passwords, bearer tokens and the
  /// access/refresh tokens the login response returns.
  static String _redactSecrets(String line) {
    // `replaceAll` inserts `$1` literally -- only `replaceAllMapped` expands a
    // group -- so the prefix is carried over from the match itself.
    String mask(String input, RegExp pattern) =>
        input.replaceAllMapped(pattern, (m) => '${m[1]}<redacted>');

    var out = mask(
      line,
      RegExp(r'(password\w*"?\s*[:=]\s*"?)([^",}\s]+)', caseSensitive: false),
    );
    out = mask(
      out,
      RegExp(
        r'((?:access|refresh)token"?\s*[:=]\s*"?)([^",}\s]+)',
        caseSensitive: false,
      ),
    );
    out = mask(out, RegExp(r'(Bearer\s+)(\S+)', caseSensitive: false));
    out = mask(out, RegExp(r'(cooktoken=)([^;\s]+)', caseSensitive: false));
    return out;
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
