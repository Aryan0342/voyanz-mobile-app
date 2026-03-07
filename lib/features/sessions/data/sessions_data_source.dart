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
}
