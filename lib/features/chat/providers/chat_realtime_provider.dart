import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';

/// Registers real-time chat handlers on the WebSocket, feeds unread badges
/// from the `notreaded` payload and invalidates chat providers so UI
/// refreshes automatically.
final chatRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(webSocketServiceProvider);

  void handler(Map<String, dynamic> event) {
    _applyUnreadSnapshot(ref, event);

    final messages = _extractMessages(event);
    if (messages.isNotEmpty) {
      final chgrIds = messages
          .map((m) => m.chgrId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final chgrId in chgrIds) {
        ref.invalidate(chatMessagesProvider(chgrId));

        try {
          final relevant = messages.where((m) => m.chgrId == chgrId).toList();
          ref
              .read(chatMessagesNotifierProvider(chgrId).notifier)
              .mergeIncoming(relevant);
        } catch (_) {
          // ignore: no-op
        }
      }

      ref.invalidate(chatGroupsProvider);
      return;
    }
  }

  void unreadHandler(Map<String, dynamic> event) {
    _applyUnreadSnapshot(ref, event);
    ref.invalidate(chatGroupsProvider);
  }

  ws.on('chat_message_new', handler);
  ws.on('chat_cmptupdated', unreadHandler);

  ref.onDispose(() {
    try {
      ws.off('chat_message_new', handler);
      ws.off('chat_cmptupdated', unreadHandler);
    } catch (_) {}
  });
});

/// The server sends the recipient's current unread rows as
/// `[{chme_id, chgr_id, co_id}, ...]`. Treat it as an authoritative
/// snapshot per group and store counts for badge rendering.
void _applyUnreadSnapshot(Ref ref, Map<String, dynamic> event) {
  final raw = event['notreaded'];
  if (raw is! List) return;

  final counts = <String, int>{};
  for (final row in raw) {
    if (row is! Map<String, dynamic>) continue;
    final chgrId = row['chgr_id']?.toString();
    if (chgrId == null || chgrId.isEmpty) continue;
    counts[chgrId] = (counts[chgrId] ?? 0) + 1;
  }

  // Groups that had a badge but are absent now are read -> drop to zero.
  final current = ref.read(chatUnreadCountsProvider);
  final merged = <String, int>{...current};
  for (final id in merged.keys.toList()) {
    if (!counts.containsKey(id)) merged[id] = 0;
  }
  merged.addAll(counts);

  ref.read(chatUnreadCountsProvider.notifier).state = merged;
}

List<ChatMessage> _extractMessages(Map<String, dynamic> event) {
  final rawMessages = event['messages'];
  if (rawMessages is List) {
    return rawMessages
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  final rawMessage = event['message'] ?? event['data'];
  if (rawMessage is Map<String, dynamic>) {
    return [ChatMessage.fromJson(rawMessage)];
  }

  return const [];
}
