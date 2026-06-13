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
      token: json['token']?.toString() ?? '',
      room:
          json['room']?.toString() ??
          json['channelName']?.toString() ??
          json['channel']?.toString() ??
          '',
      identity: json['identity']?.toString(),
      uid: json['uid'] is int
          ? json['uid'] as int
          : int.tryParse(json['uid']?.toString() ?? ''),
      provider: json['provider']?.toString() ?? 'agora',
      appId:
          json['appId']?.toString() ??
          json['app_id']?.toString() ??
          json['agoraAppId']?.toString(),
    );
  }
}
