import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';

class AppointmentsDataSource {
  final Dio _dio;

  AppointmentsDataSource(this._dio);

  /// POST /web/1.0/registration  body: { ap_id }
  Future<Map<String, dynamic>> register({required String apId}) async {
    final response = await _dio.post(
      ApiEndpoints.registration,
      data: {'ap_id': apId},
    );
    return response.data as Map<String, dynamic>;
  }
}
