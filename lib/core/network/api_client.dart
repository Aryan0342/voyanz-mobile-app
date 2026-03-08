import 'package:dio/dio.dart';
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

  static Dio create(TokenStorage tokenStorage) {
    if (_instance != null) return _instance!;

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
  static void reset() => _instance = null;
}
