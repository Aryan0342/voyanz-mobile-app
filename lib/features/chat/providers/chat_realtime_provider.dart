import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';

/// Registers real-time chat handlers on the WebSocket and invalidates
/// chat providers when new messages arrive so UI refreshes automatically.
final chatRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(webSocketServiceProvider);

  void handler(Map<String, dynamic> event) {
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

    // Legacy fallback: older builds used a single payload under message/data.
    final rawPayload = event['message'] ?? event['data'];
    final payload = rawPayload is Map<String, dynamic>
        ? rawPayload
        : const <String, dynamic>{};
    final chgrId = (payload['chgr_id'] ?? payload['chgrId'])?.toString();
    if (chgrId == null || chgrId.isEmpty) return;

    ref.invalidate(chatMessagesProvider(chgrId));
    ref.invalidate(chatGroupsProvider);
    try {
      ref.read(chatMessagesNotifierProvider(chgrId).notifier).refresh();
    } catch (_) {
      // ignore: no-op
    }
  }

  void unreadHandler(Map<String, dynamic> _) {
    ref.invalidate(chatGroupsProvider);
  }

  ws.on('chat_message_new', handler);
  ws.on('chat_message', handler);
  ws.on('chat_cmptupdated', unreadHandler);

  ref.onDispose(() {
    try {
      ws.off('chat_message_new', handler);
      ws.off('chat_message', handler);
      ws.off('chat_cmptupdated', unreadHandler);
    } catch (_) {}
  });
});

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
