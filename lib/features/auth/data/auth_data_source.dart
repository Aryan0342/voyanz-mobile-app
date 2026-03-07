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
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> getUserInfos() async {
    final response = await _dio.get(ApiEndpoints.userInfos);
    final body = response.data as Map<String, dynamic>;
    return User.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }
}
