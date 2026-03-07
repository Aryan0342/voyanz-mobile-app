import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class SessionsRepository {
  final SessionsDataSource _ds;

  SessionsRepository(this._ds);

  Future<VideoToken> getVideoToken({
    required String seId,
    required String coId,
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
    return _ds.getVideoAccessToken(seId: seId, coId: coId);
  }

  Future<void> sendHeartbeat(String seId) async {
    if (kUseMockBackend) {
      return;
    }
    return _ds.sendHeartbeat(seId);
  }
}
