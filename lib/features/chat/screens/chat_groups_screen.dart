import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/utils/string_utils.dart';
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
            child: CircularProgressIndicator(color: AppColors.mediumPurple),
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
                const SizedBox(height: 8),
                Text(
                  'An error occurred. Please try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 20,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.messages,
                              style: GoogleFonts.jost(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.searchConversations,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  ),
                ],
              );
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
                    child: _RevealIn(
                      delayMs: 20,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        child: Center(
                          child: Text(
                            t.messages,
                            style: GoogleFonts.jost(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Pinned Section ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PinnedSection(groups: filtered),
                    ),
                  ),
                  // ── Search bar ──
                  SliverToBoxAdapter(
                    child: _RevealIn(
                      delayMs: 70,
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
                            fillColor: Colors.white.withValues(alpha: 0.6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
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
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Text(
                          'All Messages',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final g = filtered[i];
                          return _RevealIn(
                            delayMs: 120 + (i * 35),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ConversationCard(
                                group: g,
                                onTap: () => context.push('/chat/${g.chgrId}'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
                      stripHtml(group.lastMessage!),
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
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mediumPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealIn extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _RevealIn({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.mediumPurple.withValues(alpha: 0.16),
                      AppColors.aqua.withValues(alpha: 0.11),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 42,
                  color: AppColors.deepIndigo,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.noConversationsYet,
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.startChatExplore,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedSection extends StatelessWidget {
  final List<dynamic> groups;
  
  const _PinnedSection({required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    // Use up to the first 5 groups for the pinned section
    final pinnedGroups = groups.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pinned',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: pinnedGroups.length,
            itemBuilder: (context, index) {
              final group = pinnedGroups[index];
              final name = group.otherUserName ?? group.name ?? 'Chat';
              final firstName = name.split(' ').first;
              
              return _PinnedAvatar(
                name: firstName,
                image: group.otherUserAvatar,
                icon: group.otherUserAvatar == null ? Icons.person_outline : null,
                isOnline: index % 2 == 0, // Using mock online status for visual parity
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PinnedAvatar extends StatelessWidget {
  final String name;
  final String? image;
  final IconData? icon;
  final bool? isOnline;

  const _PinnedAvatar({required this.name, this.image, this.icon, this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: image == null ? null : AppGradients.card,
                  color: image == null ? Colors.white.withValues(alpha: 0.6) : null,
                ),
                padding: image != null ? const EdgeInsets.all(4) : EdgeInsets.zero,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: image != null
                      ? ClipOval(child: Image.network(image!, fit: BoxFit.cover))
                      : Icon(icon, color: AppColors.textPrimary, size: 26),
                ),
              ),
              if (isOnline != null)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline! ? AppColors.online : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
