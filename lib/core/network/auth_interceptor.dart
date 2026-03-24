import 'package:dio/dio.dart';
import 'package:voyanz/core/storage/token_storage.dart';

/// Injects the stored access token into every outgoing request.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  static const Set<String> _publicPaths = {
    '/api/1.0/login',
    '/web/1.0/account',
  };

  AuthInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Do not attach stale bearer token to public endpoints.
    if (_publicPaths.contains(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await _tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: Handle 401 → refresh token logic when refresh endpoint is confirmed.
    handler.next(err);
  }
}
