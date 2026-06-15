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
      final body = _asMap(response.data);
      _throwIfApiError(body);
      return LoginResponse.fromJson(body);
    } on DioException catch (e) {
      throw _readableDioException(e, 'Login request failed');
    }
  }

  Future<LoginResponse> signUp({required Map<String, dynamic> body}) async {
    try {
      final response = await _dio.post(ApiEndpoints.createAccount, data: body);
      final payload = _asMap(response.data);
      _throwIfApiError(payload);
      return LoginResponse.fromJson(payload);
    } on DioException catch (e) {
      throw _readableDioException(e, 'Signup request failed');
    }
  }

  Future<User> getUserInfos() async {
    final response = await _dio.get(ApiEndpoints.userInfos);
    final body = _asMap(response.data);
    _throwIfApiError(body);
    return User.fromJson(_asMap(body['data'] ?? body));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception('Unexpected API response');
  }

  Exception _readableDioException(DioException e, String fallback) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final body = _asMap(data);
      final err = body['err'];
      if (err is Map) {
        final errBody = _asMap(err);
        final msg =
            errBody['message']?.toString() ??
            errBody['key']?.toString() ??
            errBody['code']?.toString();
        if (msg != null && msg.trim().isNotEmpty) {
          return Exception(msg);
        }
      }

      final topLevelError = body['error']?.toString();
      if (topLevelError != null && topLevelError.trim().isNotEmpty) {
        return Exception(topLevelError);
      }
    }

    if (status == 401) {
      return Exception('Invalid email or password');
    }

    return Exception('$fallback (${status ?? 'network error'})');
  }

  void _throwIfApiError(Map<String, dynamic> body) {
    final topLevelError = body['error'];
    if (topLevelError != null &&
        topLevelError != false &&
        topLevelError != 0) {
      final message = body['message']?.toString() ?? topLevelError.toString();
      throw Exception(message);
    }

    final err = body['err'];
    if (err == null || err == false || err == 0) return;

    if (err is Map) {
      final errBody = _asMap(err);
      final message =
          errBody['message']?.toString() ??
          errBody['key']?.toString() ??
          'API error';
      throw Exception(message);
    }

    throw Exception(err.toString());
  }
}
