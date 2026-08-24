import 'package:dio/dio.dart';
import 'package:voyanz/core/storage/token_storage.dart';

/// Injects the stored access token into every outgoing request.
///
/// Also detects token rejection (HTTP 401 with `err.key`
/// `token_expired` / `not_found_user`) and fires [onSessionExpired],
/// per CHAT_AUDIO §1.7 and WEBSOCKET §8 ("treat as logged-out").
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  static const Set<String> _publicPaths = {
    '/api/1.0/login',
    '/web/1.0/account',
  };

  /// Called once per rejection episode so the app can force logout.
  /// Wired by [AuthNotifier]; navigation to /login happens via router redirect.
  static Future<void> Function()? onSessionExpired;
  static bool _handlingSessionExpired = false;

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
      // Some backend middlewares still read the legacy mobile auth header.
      options.headers['x-auth-accesstoken'] = token;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isTokenRejected(err)) {
      _fireSessionExpired();
    }
    handler.next(err);
  }

  bool _isTokenRejected(DioException err) {
    if (err.response?.statusCode != 401) return false;
    if (_publicPaths.contains(err.requestOptions.path)) return false;

    final data = err.response?.data;
    var key = '';
    if (data is Map) {
      final e = data['err'];
      if (e is Map) {
        key = (e['key'] ?? e['code'] ?? '').toString();
      } else if (e != null && e.toString() != 'null') {
        key = e.toString();
      }
      if (key.isEmpty) key = (data['error'] ?? '').toString();
    }

    return key == 'token_expired' || key == 'not_found_user';
  }

  void _fireSessionExpired() {
    final callback = onSessionExpired;
    if (callback == null || _handlingSessionExpired) return;
    // Several in-flight requests can 401 at once — force logout only once.
    _handlingSessionExpired = true;
    Future(() async {
      try {
        await callback();
      } catch (_) {
        // Never let forced-logout failures break error propagation.
      } finally {
        _handlingSessionExpired = false;
      }
    });
  }
}
