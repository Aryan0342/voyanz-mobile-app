import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';

class ChatGroupsScreen extends ConsumerStatefulWidget {
  const ChatGroupsScreen({super.key});

  @override
  ConsumerState<ChatGroupsScreen> createState() => _ChatGroupsScreenState();
}

class _ChatGroupsScreenState extends ConsumerState<ChatGroupsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final groupsAsync = ref.watch(chatGroupsProvider);

    return GradientScaffold(
      body: SafeArea(
        child: groupsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  t.failedLoadConversations,
                  style: GoogleFonts.montserrat(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return _EmptyState();
            }

            final searchQuery = _searchCtrl.text.toLowerCase();
            final filtered = searchQuery.isEmpty
                ? groups
                : groups.where((g) {
                    final name = (g.otherUserName ?? g.name ?? '')
                        .toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(chatGroupsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── Header with title ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        t.messages,
                        style: GoogleFonts.jost(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // ── Search bar ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: t.searchConversations,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceCard.withValues(
                            alpha: 0.6,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.mediumPurple.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.rosePink,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  // ── Conversations list ──
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 56,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noConversationsFound,
                              style: GoogleFonts.montserrat(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final g = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConversationCard(
                              group: g,
                              onTap: () => context.push('/chat/${g.chgrId}'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  final dynamic group;
  final VoidCallback onTap;

  const _ConversationCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.accent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rosePink.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: group.otherUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        group.otherUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.otherUserName ?? group.name ?? t.tabChat,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (group.lastMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.lastMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mediumPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.rosePink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.accent.scale(0.3),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.noConversationsYet,
            style: GoogleFonts.jost(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              t.startChatExplore,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
