import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';

class AccountDataSource {
  final Dio _dio;

  AccountDataSource(this._dio);

  /// POST /web/1.0/account
  Future<Map<String, dynamic>> createAccount({
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(ApiEndpoints.createAccount, data: body);
    final result = response.data as Map<String, dynamic>;
    _throwIfApiError(result);
    return result;
  }

  /// PUT /web/1.0/account/:co_id
  Future<Map<String, dynamic>> updateAccount({
    required String coId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.updateAccount(coId),
      data: body,
    );
    final result = response.data as Map<String, dynamic>;
    _throwIfApiError(result);
    return result;
  }

  /// PUT /web/1.0/account/description/:co_id (pro only)
  Future<Map<String, dynamic>> updateProDescription({
    required String coId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.updateProDescription(coId),
      data: body,
    );
    final result = response.data as Map<String, dynamic>;
    _throwIfApiError(result);
    return result;
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
