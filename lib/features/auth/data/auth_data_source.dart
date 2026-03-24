import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/auth/models/user.dart';

class AuthDataSource {
  final Dio _dio;

  AuthDataSource(this._dio);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'login': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      _throwIfApiError(body);
      return LoginResponse.fromJson(body);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        final err = data['err'];
        if (err is Map<String, dynamic>) {
          final msg =
              err['message']?.toString() ??
              err['key']?.toString() ??
              err['code']?.toString();
          if (msg != null && msg.trim().isNotEmpty) {
            throw Exception(msg);
          }
        }

        final topLevelError = data['error']?.toString();
        if (topLevelError != null && topLevelError.trim().isNotEmpty) {
          throw Exception(topLevelError);
        }
      }

      if (status == 401) {
        throw Exception('Invalid email or password');
      }

      throw Exception('Login request failed (${status ?? 'network error'})');
    }
  }

  Future<User> getUserInfos() async {
    final response = await _dio.get(ApiEndpoints.userInfos);
    final body = response.data as Map<String, dynamic>;
    _throwIfApiError(body);
    return User.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  void _throwIfApiError(Map<String, dynamic> body) {
    final err = body['err'];
    if (err == null) return;

    if (err is Map<String, dynamic>) {
      final message =
          err['message']?.toString() ?? err['key']?.toString() ?? 'API error';
      throw Exception(message);
    }

    throw Exception(err.toString());
  }
}
