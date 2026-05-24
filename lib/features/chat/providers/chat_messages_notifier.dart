import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/chat/data/chat_repository.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
// no-op

class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref ref;
  final String chgrId;
  final ChatRepository _repo;

  ChatMessagesNotifier(this.ref, this.chgrId)
    : _repo = ref.read(chatRepositoryProvider),
      super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getMessages(chgrId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a message with optimistic UI. Adds a local temporary message,
  /// then attempts to send via repository. On success we reload from server;
  /// on failure we remove the optimistic message and rethrow.
  Future<void> sendMessage(String content) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final senderCoId = user?.coId ?? 'unknown';
    final senderName = (user?.firstName ?? 'You');

    final optimistic = ChatMessage(
      chmeId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      chgrId: chgrId,
      senderCoId: senderCoId,
      senderName: senderName,
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // Insert optimistic message at the end (newest last)
    final current = state.value ?? <ChatMessage>[];
    final updated = List<ChatMessage>.from(current)..add(optimistic);
    state = AsyncValue.data(updated);

    try {
      await _repo.sendMessage(chgrId: chgrId, content: content);
      // Refresh from server to get canonical data
      await _load();
    } catch (e) {
      // Remove optimistic message
      final afterFailure = (state.value ?? <ChatMessage>[])
          .where((m) => m.chmeId != optimistic.chmeId)
          .toList();
      state = AsyncValue.data(afterFailure);
      rethrow;
    }
  }

  /// Forces a reload from the backend.
  Future<void> refresh() => _load();
}

final chatMessagesNotifierProvider =
    StateNotifierProvider.family<
      ChatMessagesNotifier,
      AsyncValue<List<ChatMessage>>,
      String
    >((ref, chgrId) {
      return ChatMessagesNotifier(ref, chgrId);
    });
