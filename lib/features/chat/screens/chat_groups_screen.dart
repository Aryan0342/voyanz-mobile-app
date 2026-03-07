import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';

class ChatGroupsScreen extends ConsumerWidget {
  const ChatGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(chatGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final g = groups[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: g.otherUserAvatar != null
                      ? NetworkImage(g.otherUserAvatar!)
                      : null,
                  child: g.otherUserAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(g.otherUserName ?? g.name ?? 'Chat'),
                subtitle: Text(
                  g.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/chat/${g.chgrId}'),
              );
            },
          );
        },
      ),
    );
  }
}
