import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class SessionLaunchException implements Exception {
  final String message;
  final String? sessionId;
  final int? statusCode;
  final String? seType; // "video" | "phone" | "chat"
  final String? seStatus; // "calling" | "accepted" | "inprogress"
  final String? seRoom; // Agora channel name
  final String? chgrId; // Channel group ID

  const SessionLaunchException(
    this.message, {
    this.sessionId,
    this.statusCode,
    this.seType,
    this.seStatus,
    this.seRoom,
    this.chgrId,
  });

  /// Returns true if this exception represents a session already running (409)
  /// with enough info to rejoin it.
  bool get isDuplicateSessionWithDetails =>
      statusCode == 409 &&
      sessionId != null &&
      sessionId!.isNotEmpty &&
      seType != null &&
      seRoom != null;

  /// Legacy canResume for backward compatibility.
  bool get canResume => sessionId != null && sessionId!.isNotEmpty;

  @override
  String toString() => message;
}

class SessionAuthExpiredException implements Exception {
  final String message;

  const SessionAuthExpiredException(this.message);

  @override
  String toString() => message;
}

class SessionsDataSource {
  final Dio _dio;

  SessionsDataSource(this._dio);

  /// GET /web/1.0/video/:se_id/:co_id/accesstoken
  Future<VideoToken> getVideoAccessToken({
    required String seId,
    required String coId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.videoAccessToken(seId, coId),
      );
      final body = response.data as Map<String, dynamic>;

      final err = body['err'];
      final error = body['error'];
      if (err != null) {
        if (_isAuthExpiredError(err)) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        if (err is Map<String, dynamic>) {
          final message =
              err['message']?.toString() ??
              err['key']?.toString() ??
              err['code']?.toString() ??
              'API error';
          throw Exception(message);
        }
        throw Exception(err.toString());
      }
      if (error != null) {
        if (_isAuthExpiredText(error.toString())) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        throw Exception(error.toString());
      }

      return VideoToken.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Video access token request failed',
        ),
      );
    }
  }

  /// POST /web/1.0/video/heartbeat/:se_id
  Future<void> sendHeartbeat(String seId) async {
    try {
      await _dio.post(ApiEndpoints.videoHeartbeat(seId));
    } on DioException catch (e) {
      if (_isAuthExpiredText(_extractApiErrorMessage(e, fallback: ''))) {
        throw const SessionAuthExpiredException(
          'Token expired. Please log in again.',
        );
      }
      throw Exception(
        _extractApiErrorMessage(e, fallback: 'Video heartbeat failed'),
      );
    }
  }

  /// POST /web/1.0/call/:typecall/:co_id
  Future<String> createSessionCall({
    required String typeCall,
    required String coId,
    String? apId,
  }) async {
    try {
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
        if (_isAuthExpiredError(err)) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        if (err is Map<String, dynamic>) {
          final message =
              err['message']?.toString() ??
              err['key']?.toString() ??
              'API error';
          throw Exception(message);
        }
        throw Exception(err.toString());
      }
      if (error != null) {
        if (_isAuthExpiredText(error.toString())) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        throw Exception(error.toString());
      }

      final sessionId = _extractSessionId(body);
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('Session id missing from response');
      }
      return sessionId;
    } on DioException catch (e) {
      throw _extractSessionLaunchException(
        e,
        fallback: 'Session request failed',
      );
    }
  }

  /// GET /web/1.0/session/:se_id
  Future<SessionStatus> getSessionStatus(String seId) async {
    try {
      final response = await _dio.get(ApiEndpoints.sessionStatus(seId));
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected session status response format');
      }

      final err = body['err'];
      final error = body['error'];
      if (err != null) {
        if (_isAuthExpiredError(err)) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        if (err is Map<String, dynamic>) {
          final message =
              err['message']?.toString() ??
              err['key']?.toString() ??
              'API error';
          throw Exception(message);
        }
        throw Exception(err.toString());
      }
      if (error != null) {
        if (_isAuthExpiredText(error.toString())) {
          throw const SessionAuthExpiredException(
            'Token expired. Please log in again.',
          );
        }
        throw Exception(error.toString());
      }

      final payload = _extractStatusPayload(body);
      return SessionStatus.fromJson(seId, payload);
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(e, fallback: 'Session status request failed'),
      );
    }
  }

  Map<String, dynamic> _extractStatusPayload(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nestedSession = data['session'];
      if (nestedSession is Map<String, dynamic>) {
        return nestedSession;
      }
      return data;
    }

    final session = body['session'];
    if (session is Map<String, dynamic>) {
      return session;
    }

    return body;
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
      return 'Request was forbidden by the server (403)';
    }

    return '$fallback (${statusCode ?? 'network error'})';
  }

  bool _isAuthExpiredError(dynamic err) {
    if (err is Map<String, dynamic>) {
      final key = err['key']?.toString().toLowerCase() ?? '';
      final message = err['message']?.toString().toLowerCase() ?? '';
      return key.contains('token_expired') ||
          message.contains('token expir') ||
          message.contains('refresh token');
    }

    return _isAuthExpiredText(err.toString());
  }

  bool _isAuthExpiredText(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('token_expired') ||
        normalized.contains('token expir') ||
        normalized.contains('refresh token');
  }

  SessionLaunchException _extractSessionLaunchException(
    DioException exception, {
    required String fallback,
  }) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? sessionId;
    String? seType;
    String? seStatus;
    String? seRoom;
    String? chgrId;

    if (data is Map<String, dynamic>) {
      sessionId = _extractSessionId(data);
      // Extract 409-specific fields from duplicate-session response
      if (statusCode == 409) {
        seType = data['se_type']?.toString();
        seStatus = data['se_status']?.toString();
        seRoom = data['se_room']?.toString();
        chgrId = data['chgr_id']?.toString();
      }
    }

    final message = _extractApiErrorMessage(exception, fallback: fallback);

    return SessionLaunchException(
      message,
      sessionId: sessionId,
      statusCode: statusCode,
      seType: seType,
      seStatus: seStatus,
      seRoom: seRoom,
      chgrId: chgrId,
    );
  }
}
