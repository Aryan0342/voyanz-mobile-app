import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/chat/data/chat_data_source.dart';
import 'package:voyanz/features/chat/data/chat_repository.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

final chatDataSourceProvider = Provider<ChatDataSource>((ref) {
  return ChatDataSource(ref.watch(dioProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(chatDataSourceProvider));
});

final chatGroupsProvider = FutureProvider<List<ChatGroup>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  return ref.watch(chatRepositoryProvider).getGroups(
    myCoId: user?.coId,
    myRole: user?.role,
  );
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  chgrId,
) async {
  return ref.watch(chatRepositoryProvider).getMessages(chgrId);
});

/// Unread message counts per chat group (chgr_id -> count).
/// Fed by the `notreaded` payload of WS events (`chat_message_new`,
/// `chat_cmptupdated`) and reset when a thread is opened / marked read.
final chatUnreadCountsProvider = StateProvider<Map<String, int>>((ref) => {});

final chatMessagesPageProvider =
    FutureProvider.family<
      ChatMessagesPage,
      ({String chgrId, int limit, int offset})
    >((ref, params) async {
      return ref
          .watch(chatRepositoryProvider)
          .getMessagesPage(
            params.chgrId,
            limit: params.limit,
            offset: params.offset,
          );
    });
