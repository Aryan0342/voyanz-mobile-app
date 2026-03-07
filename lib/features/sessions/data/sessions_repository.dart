import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class SessionsRepository {
  final SessionsDataSource _ds;

  SessionsRepository(this._ds);

  Future<VideoToken> getVideoToken({
    required String seId,
    required String coId,
  }) => _ds.getVideoAccessToken(seId: seId, coId: coId);

  Future<void> sendHeartbeat(String seId) => _ds.sendHeartbeat(seId);
}
