import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/core/network/api_exception.dart';

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

  /// PUT /web/1.0/account/:co_id with `co_password` + `co_password2`.
  Future<void> changePassword({
    required String coId,
    required String password,
    required String confirmation,
  }) async {
    await updateAccount(
      coId: coId,
      body: {'co_password': password, 'co_password2': confirmation},
    );
  }

  /// PUT /web/1.0/account/:co_id with `co_email1` (format and uniqueness are
  /// checked server-side).
  Future<void> changeEmail({required String coId, required String email}) async {
    await updateAccount(coId: coId, body: {'co_email1': email});
  }

  /// DELETE /web/1.0/account/:co_id.
  ///
  /// Returns true when the server only *requested* deletion (professionals:
  /// the account is deactivated and logged out now, our team finalises once
  /// payouts are settled). Customers are anonymised immediately.
  Future<bool> deleteAccount({required String coId}) async {
    final response = await _dio.delete(ApiEndpoints.deleteAccount(coId));
    final body = response.data;
    if (body is Map<String, dynamic>) {
      _throwIfApiError(body);
      final data = body['data'];
      if (data is Map && data['deletion_requested'] == true) return true;
    }
    return false;
  }

  /// POST /web/1.0/account/:co_id/image with a base64 data URI.
  Future<void> uploadProfileImage({
    required String coId,
    required String dataUri,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.accountImage(coId),
      data: {'image': dataUri},
    );
    final body = response.data;
    if (body is Map<String, dynamic>) _throwIfApiError(body);
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

    if (err is Map<String, dynamic>) {
      final key = err['key']?.toString();
      final rawCode = err['code'];
      final message =
          err['message']?.toString() ?? key ?? 'API error';
      // Carry the key and code: the message is prose and cannot be matched on.
      throw ApiException(
        message,
        key: key,
        code: rawCode is int ? rawCode : int.tryParse('$rawCode'),
      );
    }

    throw Exception(err.toString());
  }
}
