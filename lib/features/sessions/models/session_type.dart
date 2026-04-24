String? normalizeSessionType(dynamic raw) {
  if (raw == null) return null;

  if (raw is num) {
    if (raw == 1) return 'phone';
    if (raw == 2) return 'video';
    if (raw == 3) return 'chat';
  }

  final text = raw.toString().trim().toLowerCase();
  if (text.isEmpty) return null;

  if (text == '1') return 'phone';
  if (text == '2') return 'video';
  if (text == '3') return 'chat';

  if (text == 'phone' || text == 'audio' || text == 'call') return 'phone';
  if (text == 'video' || text == 'visio') return 'video';
  if (text == 'chat' || text == 'text' || text == 'message') return 'chat';

  if (text.contains('phone') ||
      text.contains('audio') ||
      text.contains('tel') ||
      text.contains('voice')) {
    return 'phone';
  }

  if (text.contains('video') ||
      text.contains('visio') ||
      text.contains('cam')) {
    return 'video';
  }

  if (text.contains('chat') ||
      text.contains('text') ||
      text.contains('message')) {
    return 'chat';
  }

  return null;
}
