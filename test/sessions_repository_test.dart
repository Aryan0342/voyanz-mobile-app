import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/sessions/data/sessions_repository.dart';
import 'package:voyanz/features/sessions/models/video_token.dart';

class _FakeSessionsDataSource extends SessionsDataSource {
  _FakeSessionsDataSource() : super(Dio());

  String? lastType;
  String? lastCoId;
  String? lastApId;
  String? lastHeartbeatSeId;

  @override
  Future<String> createSessionCall({required String typeCall, required String coId, String? apId}) async {
    lastType = typeCall;
    lastCoId = coId;
    lastApId = apId;
    return 'se-999';
  }

  @override
  Future<VideoToken> getVideoAccessToken({required String seId, required String coId}) async {
    return const VideoToken(
      token: 'tok-1',
      room: 'room-1',
      provider: 'agora',
      appId: 'app-1',
      uid: 7,
    );
  }

  @override
  Future<void> sendHeartbeat(String seId) async {
    lastHeartbeatSeId = seId;
  }
}

void main() {
  test('create session + video token + heartbeat critical session flows', () async {
    final ds = _FakeSessionsDataSource();
    final repo = SessionsRepository(ds);

    final seId = await repo.createSessionCall(typeCall: 'video', coId: 'co-1', apId: 'ap-7');
    final token = await repo.getVideoToken(seId: seId, coId: 'co-1');
    await repo.sendHeartbeat(seId);

    expect(seId, 'se-999');
    expect(ds.lastType, 'video');
    expect(ds.lastCoId, 'co-1');
    expect(ds.lastApId, 'ap-7');
    expect(token.room, 'room-1');
    expect(token.provider, 'agora');
    expect(ds.lastHeartbeatSeId, 'se-999');
  });
}
