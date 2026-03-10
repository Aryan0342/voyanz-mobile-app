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
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'login': email, 'password': password},
    );
    final body = response.data as Map<String, dynamic>;
    _throwIfApiError(body);
    return LoginResponse.fromJson(body);
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
