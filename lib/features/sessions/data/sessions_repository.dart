import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/session_status.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class SessionsRepository {
  final SessionsDataSource _ds;

  SessionsRepository(this._ds);

  Future<VideoToken> getVideoToken({
    required String seId,
    required String coId,
    String? connectionId,
  }) async {
    if (kUseMockBackend) {
      return VideoToken(
        token: 'mock-video-token-$seId-$coId',
        room: 'voyanz-room-$seId',
        identity: coId,
        uid: 1,
        provider: 'agora',
        appId: 'mock-app-id',
      );
    }
    return _ds.getVideoAccessToken(
      seId: seId,
      coId: coId,
      connectionId: connectionId,
    );
  }

  Future<void> sendHeartbeat(String seId, {String? connectionId}) async {
    if (kUseMockBackend) {
      return;
    }
    return _ds.sendHeartbeat(seId, connectionId: connectionId);
  }

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
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return SessionLaunchResult(
        sessionId: 'mock-se-${DateTime.now().millisecondsSinceEpoch}',
        seType: typeCall,
        seStatus: 'inprogress',
        chgrId: typeCall == 'chat' ? 'chat-001' : null,
      );
    }
    return _ds.createSessionCall(
      typeCall: typeCall,
      coId: coId,
      apId: apId,
      language: language,
      tool: tool,
      recordingReplayOption: recordingReplayOption,
      avatar: avatar,
      options: options,
    );
  }

  Future<SessionStatus> getSessionStatus(String seId) async {
    if (kUseMockBackend) {
      return SessionStatus(
        seId: seId,
        status: 'active',
        raw: const {'source': 'mock'},
      );
    }
    return _ds.getSessionStatus(seId);
  }
}
