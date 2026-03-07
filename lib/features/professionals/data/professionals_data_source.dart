import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class ProfessionalsDataSource {
  final Dio _dio;

  ProfessionalsDataSource(this._dio);

  Future<List<Professional>> getProfessionals() async {
    final response = await _dio.get(ApiEndpoints.professionals);
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map((e) => Professional.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProfessionalDetail> getProfessionalInfos(String coId) async {
    final response = await _dio.get(ApiEndpoints.professionalInfos(coId));
    final body = response.data as Map<String, dynamic>;
    return ProfessionalDetail.fromJson(
      body['data'] as Map<String, dynamic>? ?? body,
    );
  }

  Future<List<dynamic>> getDisponibilities() async {
    final response = await _dio.get(ApiEndpoints.professionalDisponibilities);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as List? ?? [];
  }

  Future<void> createDisponibility(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.createDisponibilities, data: data);
  }
}
