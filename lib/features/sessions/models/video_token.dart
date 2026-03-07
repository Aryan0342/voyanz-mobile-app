/// Token + metadata returned by GET /web/1.0/video/:se_id/:co_id/accesstoken
class VideoToken {
  final String token;
  final String room;
  final String? identity;
  final int? uid;
  final String provider; // 'agora' | 'twilio'
  final String? appId;

  const VideoToken({
    required this.token,
    required this.room,
    this.identity,
    this.uid,
    required this.provider,
    this.appId,
  });

  bool get isAgora => provider == 'agora';

  factory VideoToken.fromJson(Map<String, dynamic> json) {
    return VideoToken(
      token: json['token'] as String? ?? '',
      room: json['room'] as String? ?? '',
      identity: json['identity'] as String?,
      uid: json['uid'] as int?,
      provider: json['provider'] as String? ?? 'agora',
      appId: json['appId'] as String?,
    );
  }
}
