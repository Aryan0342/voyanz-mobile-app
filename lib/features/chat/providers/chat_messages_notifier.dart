import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/chat/data/chat_repository.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

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
      state = AsyncValue.data(_mergeAndSort(list));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a message with optimistic UI. Adds a local temporary message,
  /// then replaces it with the created message returned by the backend.
  /// On failure we remove the optimistic message and rethrow.
  Future<void> sendMessage(String content) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final senderCoId = user?.coId ?? 'unknown';
    final senderName = (user?.firstName ?? 'You');

    final optimistic = ChatMessage(
      chmeId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      chgrId: chgrId,
      senderCoId: senderCoId,
      senderName: senderName,
      type: 'text',
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // Insert optimistic message at the end (newest last)
    final current = state.value ?? <ChatMessage>[];
    state = AsyncValue.data(_mergeAndSort([...current, optimistic]));

    try {
      final created = await _repo.sendMessage(chgrId: chgrId, content: content);
      final withoutOptimistic = (state.value ?? <ChatMessage>[])
          .where((m) => m.chmeId != optimistic.chmeId)
          .toList();
      state = AsyncValue.data(_mergeAndSort([...withoutOptimistic, created]));
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

  void mergeIncoming(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final current = state.value ?? <ChatMessage>[];
    state = AsyncValue.data(_mergeAndSort([...current, ...messages]));
  }

  List<ChatMessage> _mergeAndSort(List<ChatMessage> messages) {
    final byId = <String, ChatMessage>{};
    final localMessages = <ChatMessage>[];

    for (final message in messages) {
      if (message.chmeId.startsWith('local-')) {
        localMessages.add(message);
        continue;
      }
      byId[message.chmeId] = message;
    }

    final merged = [...byId.values, ...localMessages];
    merged.sort((a, b) {
      final aId = a.numericId;
      final bId = b.numericId;
      if (aId != null && bId != null) return aId.compareTo(bId);
      if (aId != null) return -1;
      if (bId != null) return 1;
      return a.chmeId.compareTo(b.chmeId);
    });
    return merged;
  }
}

final chatMessagesNotifierProvider =
    StateNotifierProvider.family<
      ChatMessagesNotifier,
      AsyncValue<List<ChatMessage>>,
      String
    >((ref, chgrId) {
      return ChatMessagesNotifier(ref, chgrId);
    });
