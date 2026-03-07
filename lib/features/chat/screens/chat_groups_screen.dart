import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';

class ChatGroupsScreen extends ConsumerWidget {
  const ChatGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(chatGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversations',
          style: GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: groupsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.rosePink),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: groups.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.mediumPurple.withValues(alpha: 0.1),
              height: 1,
              indent: 72,
            ),
            itemBuilder: (_, i) {
              final g = groups[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.accent,
                  ),
                  child: g.otherUserAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            g.otherUserAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                ),
                title: Text(
                  g.otherUserName ?? g.name ?? 'Chat',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: g.lastMessage != null
                    ? Text(
                        g.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
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
