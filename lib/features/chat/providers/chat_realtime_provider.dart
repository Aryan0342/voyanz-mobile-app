import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';

/// Registers real-time chat handlers on the WebSocket and invalidates
/// chat providers when new messages arrive so UI refreshes automatically.
final chatRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(webSocketServiceProvider);

  void handler(Map<String, dynamic> event) {
    // payload may be under `message` or `data` depending on server
    final payload =
        (event['message'] ?? event['data']) as Map<String, dynamic>? ?? {};

    final chgrId =
        (payload['chgr_id'] ?? payload['chgrId'] ?? payload['chgrId'])
            ?.toString();
    if (chgrId != null && chgrId.isNotEmpty) {
      // Refresh messages for the specific conversation and refresh groups
      ref.invalidate(chatMessagesProvider(chgrId));
      ref.invalidate(chatGroupsProvider);

      // Also trigger notifier refresh if a notifier exists for this chgrId
      try {
        ref.read(chatMessagesNotifierProvider(chgrId).notifier).refresh();
      } catch (_) {
        // ignore: no-op
      }
    }
  }

  ws.on('chat_message', handler);

  ref.onDispose(() {
    try {
      ws.off('chat_message', handler);
    } catch (_) {}
  });
});
