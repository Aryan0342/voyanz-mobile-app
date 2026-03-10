import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class ProfessionalsDataSource {
  final Dio _dio;

  ProfessionalsDataSource(this._dio);

  Future<List<Professional>> getProfessionals() async {
    final response = await _dio.get(ApiEndpoints.professionals);
    final body = response.data as Map<String, dynamic>;

    final topLevelError = body['error'];
    final wrappedError = body['err'];
    if (topLevelError != null) {
      throw Exception('Professionals API error: $topLevelError');
    }
    if (wrappedError is Map<String, dynamic> && wrappedError.isNotEmpty) {
      final message =
          wrappedError['message'] ?? wrappedError['code'] ?? 'Unknown error';
      throw Exception('Professionals API error: $message');
    }

    // Backend variants can return list in `data` or `allProfessionals`.
    final list =
        (body['data'] as List?) ??
        (body['allProfessionals'] as List?) ??
        (body['recommendedProfessionals'] as List?) ??
        const [];

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

  Future<void> setProfessionalFavorite(String coId, bool isFavorite) async {
    await _dio.post(
      ApiEndpoints.professionalFavorite(coId),
      data: {'favorite': isFavorite, 'co_favorite': isFavorite ? 1 : 0},
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
