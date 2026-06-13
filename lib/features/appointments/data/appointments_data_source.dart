import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';

class AppointmentsDataSource {
  final Dio _dio;

  AppointmentsDataSource(this._dio);

  /// POST /web/1.0/registration  body: { ap_id }
  Future<Map<String, dynamic>> register({required String apId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registration,
        data: {'ap_id': apId},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected appointment registration response');
      }
      _throwIfApiError(body);
      final data = body['data'];
      return data is Map<String, dynamic> ? data : body;
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(e, fallback: 'Appointment registration failed'),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException exception, {
    required String fallback,
  }) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final err = data['err'];
      if (err is Map<String, dynamic>) {
        final message =
            err['message']?.toString() ??
            err['key']?.toString() ??
            err['code']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }

      final message =
          data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (statusCode == 403) {
      return 'Appointment registration was forbidden by the server (403)';
    }

    return '$fallback (${statusCode ?? 'network error'})';
  }

  void _throwIfApiError(Map<String, dynamic> body) {
    final err = body['err'];
    if (err != null && err != false && err != 0) {
      if (err is Map<String, dynamic>) {
        final message =
            err['message']?.toString() ??
            err['key']?.toString() ??
            err['code']?.toString();
        throw Exception(message == null || message.trim().isEmpty
            ? 'Appointment registration failed'
            : message);
      }
      throw Exception(err.toString());
    }

    final topLevelError = body['error'];
    if (topLevelError != null &&
        topLevelError != false &&
        topLevelError != 0) {
      final message = body['message']?.toString() ?? topLevelError.toString();
      throw Exception(message);
    }

    if (body['success'] == false) {
      final message =
          body['message']?.toString() ??
          body['error']?.toString() ??
          'Appointment registration failed';
      throw Exception(message);
    }
  }
}
