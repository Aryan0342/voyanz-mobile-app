import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';

class ProfessionalAccountDataSource {
  final Dio _dio;

  ProfessionalAccountDataSource(this._dio);

  Future<Map<String, dynamic>> getAccount() async {
    final response = await _dio.get(ApiEndpoints.professionalAccount);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      _throwIfApiError(body);
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return {};
  }

  /// GET /web/1.0/professional/profile (contract P1).
  Future<ProfessionalProfile> getProfile() async {
    final response = await _dio.get(ApiEndpoints.professionalProfile);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      _throwIfApiError(body);
      return ProfessionalProfile.fromJson(body);
    }
    return const ProfessionalProfile();
  }

  /// POST /web/1.0/professional/accept-cgs — the server expects the string
  /// "1" (contract P3).
  Future<void> acceptCgs() async {
    final response = await _dio.post(
      ApiEndpoints.acceptCgs,
      data: {'cgs_accepted': '1'},
    );
    final body = response.data;
    if (body is Map<String, dynamic>) _throwIfApiError(body);
  }

  void _throwIfApiError(Map<String, dynamic> body) {
    final topLevelError = body['error'];
    if (topLevelError != null && topLevelError != false && topLevelError != 0) {
      final message = body['message']?.toString() ?? topLevelError.toString();
      throw Exception(message);
    }

    final err = body['err'];
    if (err == null || err == false || err == 0) return;

    if (err is Map<String, dynamic>) {
      final message =
          err['message']?.toString() ?? err['key']?.toString() ?? 'API error';
      throw Exception(message);
    }

    throw Exception(err.toString());
  }
}
