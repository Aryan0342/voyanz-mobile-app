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
      seType!.isNotEmpty;

  String? get resolvedSessionId {
    final direct = sessionId?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final fromKeyedPattern = RegExp(
      r'(?:se[_-]?id|session[_-]?id)\D*([A-Za-z0-9-]{3,})',
      caseSensitive: false,
    ).firstMatch(message);
    final keyedId = fromKeyedPattern?.group(1)?.trim();
    if (keyedId != null && keyedId.isNotEmpty) return keyedId;

    final fromPathPattern = RegExp(
      r'/session/(?:wait|status|call)/([A-Za-z0-9-]{3,})',
      caseSensitive: false,
    ).firstMatch(message);
    final pathId = fromPathPattern?.group(1)?.trim();
    if (pathId != null && pathId.isNotEmpty) return pathId;

    return null;
  }

  /// Legacy canResume for backward compatibility.
  bool get canResume => resolvedSessionId != null;

  @override
  String toString() => message;
}

class SessionLaunchResult {
  final String sessionId;
  final String? seType;
  final String? seStatus;
  final String? seRoom;
  final String? chgrId;
  final Map<String, dynamic> raw;

  const SessionLaunchResult({
    required this.sessionId,
    this.seType,
    this.seStatus,
    this.seRoom,
    this.chgrId,
    this.raw = const {},
  });

  factory SessionLaunchResult.fromException(SessionLaunchException exception) {
    return SessionLaunchResult(
      sessionId: exception.resolvedSessionId ?? '',
      seType: exception.seType,
      seStatus: exception.seStatus,
      seRoom: exception.seRoom,
      chgrId: exception.chgrId,
    );
  }
}

class SessionLaunchOptions {
  final String? apId;
  final String? language;
  final String? tool;
  final String? recordingReplayOption;
  final bool? avatar;

  const SessionLaunchOptions({
    this.apId,
    this.language,
    this.tool,
    this.recordingReplayOption,
    this.avatar,
  });

  Map<String, dynamic>? toJson() {
    final data = <String, dynamic>{
      if (apId != null && apId!.trim().isNotEmpty) 'ap_id': apId!.trim(),
      if (language != null && language!.trim().isNotEmpty)
        'language': language!.trim(),
      if (tool != null && tool!.trim().isNotEmpty) 'tool': tool!.trim(),
      if (recordingReplayOption != null &&
          recordingReplayOption!.trim().isNotEmpty)
        'recordingReplayOption': recordingReplayOption!.trim(),
      if (avatar != null) 'avatar': avatar,
    };
    return data.isEmpty ? null : data;
  }
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
    String? connectionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.videoAccessToken(seId, coId),
        queryParameters:
            connectionId == null || connectionId.trim().isEmpty
            ? null
            : {'connectionId': connectionId.trim()},
      );
      final body = response.data as Map<String, dynamic>;

      final err = body['err'];
      final error = body['error'];
      if (!_isEmptyError(err)) {
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
      if (!_isEmptyError(error)) {
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
  Future<void> sendHeartbeat(String seId, {String? connectionId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.videoHeartbeat(seId),
        data: connectionId == null || connectionId.trim().isEmpty
            ? null
            : {'connectionId': connectionId.trim()},
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final err = body['err'];
        if (!_isEmptyError(err)) {
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
                'Video heartbeat failed';
            throw Exception(message);
          }
          throw Exception(err.toString());
        }
      }
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
  Future<SessionLaunchResult> createSessionCall({
    required String typeCall,
    required String coId,
    String? apId,
    String? language,
    String? tool,
    String? recordingReplayOption,
    bool? avatar,
    SessionLaunchOptions? options,
  }) async {
    try {
      final launchOptions =
          options ??
          SessionLaunchOptions(
            apId: apId,
            language: language,
            tool: tool,
            recordingReplayOption: recordingReplayOption,
            avatar: avatar,
          );
      final response = await _dio.post(
        ApiEndpoints.createSessionCall(typeCall, coId),
        data: launchOptions.toJson(),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected create session response format');
      }

      final err = body['err'];
      final error = body['error'];
      if (!_isEmptyError(err)) {
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
      if (!_isEmptyError(error)) {
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
      return _extractLaunchResult(body, sessionId);
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
      if (!_isEmptyError(err)) {
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
      if (!_isEmptyError(error)) {
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
        return {...data, ...nestedSession};
      }
      return data;
    }

    final session = body['session'];
    if (session is Map<String, dynamic>) {
      return {...body, ...session};
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

  SessionLaunchResult _extractLaunchResult(
    Map<String, dynamic> body,
    String sessionId,
  ) {
    final data = body['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;
    final bodySession = body['session'];
    final dataSession = dataMap?['session'];
    final session = dataSession is Map<String, dynamic>
        ? dataSession
        : bodySession is Map<String, dynamic>
        ? bodySession
        : dataMap;

    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty && text != 'null') return text;
      }
      return null;
    }

    return SessionLaunchResult(
      sessionId: sessionId,
      seType: firstNonEmpty([
        body['se_type'],
        dataMap?['se_type'],
        session?['se_type'],
      ]),
      seStatus: firstNonEmpty([
        body['se_status'],
        dataMap?['se_status'],
        session?['se_status'],
      ]),
      seRoom: firstNonEmpty([
        body['se_room'],
        dataMap?['se_room'],
        session?['se_room'],
      ]),
      chgrId: firstNonEmpty([
        body['chgr_id'],
        dataMap?['chgr_id'],
        session?['chgr_id'],
      ]),
      raw: Map<String, dynamic>.from(body),
    );
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

  bool _isEmptyError(dynamic value) {
    if (value == null || value == false || value == 0) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'null' ||
          normalized == 'false' ||
          normalized == '0';
    }
    return false;
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

    String? firstNonEmpty(List<String?> values) {
      for (final value in values) {
        if (value != null && value.trim().isNotEmpty) return value;
      }
      return null;
    }

    if (data is Map<String, dynamic>) {
      sessionId = _extractSessionId(data);

      final dataPayload = data['data'];
      final nestedData = dataPayload is Map<String, dynamic>
          ? dataPayload
          : null;

      final sessionPayload = data['session'];
      final nestedSession = sessionPayload is Map<String, dynamic>
          ? sessionPayload
          : null;

      final nestedDataSessionPayload = nestedData?['session'];
      final nestedDataSession = nestedDataSessionPayload is Map<String, dynamic>
          ? nestedDataSessionPayload
          : null;

      final errPayload = data['err'];
      final nestedErr = errPayload is Map<String, dynamic> ? errPayload : null;

      final errDataPayload = nestedErr?['data'];
      final nestedErrData = errDataPayload is Map<String, dynamic>
          ? errDataPayload
          : null;

      final errSessionPayload = nestedErrData?['session'];
      final nestedErrSession = errSessionPayload is Map<String, dynamic>
          ? errSessionPayload
          : null;

      sessionId = firstNonEmpty([
        sessionId,
        nestedData == null ? null : _extractSessionId(nestedData),
        nestedErrData == null ? null : _extractSessionId(nestedErrData),
      ]);

      // Extract 409-specific fields from duplicate-session responses.
      if (statusCode == 409) {
        seType = firstNonEmpty([
          data['se_type']?.toString(),
          nestedSession?['se_type']?.toString(),
          nestedData?['se_type']?.toString(),
          nestedDataSession?['se_type']?.toString(),
          nestedErrData?['se_type']?.toString(),
          nestedErrSession?['se_type']?.toString(),
        ]);
        seStatus = firstNonEmpty([
          data['se_status']?.toString(),
          nestedSession?['se_status']?.toString(),
          nestedData?['se_status']?.toString(),
          nestedDataSession?['se_status']?.toString(),
          nestedErrData?['se_status']?.toString(),
          nestedErrSession?['se_status']?.toString(),
        ]);
        seRoom = firstNonEmpty([
          data['se_room']?.toString(),
          nestedSession?['se_room']?.toString(),
          nestedData?['se_room']?.toString(),
          nestedDataSession?['se_room']?.toString(),
          nestedErrData?['se_room']?.toString(),
          nestedErrSession?['se_room']?.toString(),
        ]);
        chgrId = firstNonEmpty([
          data['chgr_id']?.toString(),
          nestedSession?['chgr_id']?.toString(),
          nestedData?['chgr_id']?.toString(),
          nestedDataSession?['chgr_id']?.toString(),
          nestedErrData?['chgr_id']?.toString(),
          nestedErrSession?['chgr_id']?.toString(),
        ]);
      }

      final err = data['err'];
      if (err is Map<String, dynamic>) {
        final nestedMessage =
            err['message']?.toString() ??
            err['key']?.toString() ??
            err['code']?.toString();
        if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
          return SessionLaunchException(
            nestedMessage,
            sessionId: sessionId,
            statusCode: statusCode,
            seType: seType,
            seStatus: seStatus,
            seRoom: seRoom,
            chgrId: chgrId,
          );
        }
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
