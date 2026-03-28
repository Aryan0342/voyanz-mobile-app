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
    final raw = response.data;

    if (raw is List) {
      return raw;
    }

    if (raw is! Map<String, dynamic>) {
      return const [];
    }

    _throwIfApiError(raw, fallbackPrefix: 'Disponibilities API error');

    final data =
        raw['data'] ?? raw['disponibilities'] ?? raw['availability'] ?? raw;

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      // Convert map payloads like {"Monday": ["09:00"]} to list rows.
      return data.entries
          .map((e) => <String, dynamic>{'day': e.key, 'slots': e.value})
          .toList();
    }

    return const [];
  }

  Future<Map<String, dynamic>> getDisponibilitiesPayload() async {
    final response = await _dio.get(ApiEndpoints.professionalDisponibilities);
    final raw = response.data;

    if (raw is List) {
      return {
        'data': const <dynamic>[],
        'nextdisponibilities': raw,
        'days': const <dynamic>[],
      };
    }

    if (raw is! Map<String, dynamic>) {
      return {
        'data': const <dynamic>[],
        'nextdisponibilities': const <dynamic>[],
        'days': const <dynamic>[],
      };
    }

    _throwIfApiError(raw, fallbackPrefix: 'Disponibilities API error');

    final rawData = raw['data'];
    final rawNext = raw['nextdisponibilities'];
    final rawDays = raw['days'];

    final data = rawData is List ? rawData : const <dynamic>[];
    final next = rawNext is List ? rawNext : const <dynamic>[];
    final days = rawDays is List ? rawDays : const <dynamic>[];

    return {'data': data, 'nextdisponibilities': next, 'days': days};
  }

  Future<void> createDisponibility(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiEndpoints.createDisponibilities,
      data: data,
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      _throwIfApiError(raw, fallbackPrefix: 'Create disponibility failed');
    }
  }

  Future<void> updateDisponibility(
    String diId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.updateDisponibility(diId),
      data: data,
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      _throwIfApiError(raw, fallbackPrefix: 'Update disponibility failed');
    }
  }

  Future<void> deleteDisponibility(String diId) async {
    final response = await _dio.delete(ApiEndpoints.deleteDisponibility(diId));

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      _throwIfApiError(raw, fallbackPrefix: 'Delete disponibility failed');
    }
  }

  void _throwIfApiError(
    Map<String, dynamic> body, {
    required String fallbackPrefix,
  }) {
    final topLevelError = body['error'];
    final wrappedError = body['err'];

    if (topLevelError != null) {
      throw Exception('$fallbackPrefix: $topLevelError');
    }

    if (wrappedError is Map<String, dynamic> && wrappedError.isNotEmpty) {
      final message =
          wrappedError['message']?.toString() ??
          wrappedError['key']?.toString() ??
          wrappedError['code']?.toString() ??
          'Unknown error';
      throw Exception('$fallbackPrefix: $message');
    }
  }
}
