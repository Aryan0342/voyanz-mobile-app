import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class SessionsDataSource {
  final Dio _dio;

  SessionsDataSource(this._dio);

  /// GET /web/1.0/video/:se_id/:co_id/accesstoken
  Future<VideoToken> getVideoAccessToken({
    required String seId,
    required String coId,
  }) async {
    final response = await _dio.get(ApiEndpoints.videoAccessToken(seId, coId));
    final body = response.data as Map<String, dynamic>;
    return VideoToken.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  /// POST /web/1.0/video/heartbeat/:se_id
  Future<void> sendHeartbeat(String seId) async {
    await _dio.post(ApiEndpoints.videoHeartbeat(seId));
  }

  /// POST /web/1.0/call/:typecall/:co_id
  Future<String> createSessionCall({
    required String typeCall,
    required String coId,
    String? apId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.createSessionCall(typeCall, coId),
      data: apId == null ? null : {'ap_id': apId},
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected create session response format');
    }

    final err = body['err'];
    final error = body['error'];
    if (err != null) {
      if (err is Map<String, dynamic>) {
        final message =
            err['message']?.toString() ?? err['key']?.toString() ?? 'API error';
        throw Exception(message);
      }
      throw Exception(err.toString());
    }
    if (error != null) {
      throw Exception(error.toString());
    }

    final sessionId = _extractSessionId(body);
    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('Session id missing from response');
    }
    return sessionId;
  }

  String? _extractSessionId(Map<String, dynamic> body) {
    final direct = body['se_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final dataSeId = data['se_id']?.toString();
      if (dataSeId != null && dataSeId.isNotEmpty) return dataSeId;

      final session = data['session'];
      if (session is Map<String, dynamic>) {
        final nestedSeId = session['se_id']?.toString();
        if (nestedSeId != null && nestedSeId.isNotEmpty) return nestedSeId;
      }
    }

    final session = body['session'];
    if (session is Map<String, dynamic>) {
      final sessionSeId = session['se_id']?.toString();
      if (sessionSeId != null && sessionSeId.isNotEmpty) return sessionSeId;
    }

    return null;
  }
}
