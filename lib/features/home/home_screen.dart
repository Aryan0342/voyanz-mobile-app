import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/account/providers/account_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';

/// Bottom-navigation shell that wraps most authenticated screens.
/// Shows different tabs based on user role (customer vs professional).
class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  // Customer tabs
  static List<({IconData icon, IconData activeIcon, String label})>
  _buildCustomerTabs(AppTranslations t) => [
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: t.tabExplore,
    ),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: t.tabChat,
    ),
    (
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: t.tabHistory,
    ),
    (icon: Icons.star_outline, activeIcon: Icons.star, label: t.tabReviews),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: t.tabProfile),
  ];

  // Professional tabs
  static List<({IconData icon, IconData activeIcon, String label})>
  _buildProfessionalTabs(AppTranslations t) => [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: t.tabHome,
    ),
    (
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: t.tabSlots,
    ),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: t.tabChat,
    ),
    (icon: Icons.people_outline, activeIcon: Icons.people, label: t.tabClients),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: t.tabProfile),
  ];

  int _currentIndexCustomer(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/reviews')) return 3;
    if (location.startsWith('/pricing') || location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  int _currentIndexProfessional(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/availability')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/clients')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // dashboard (home)
  }

  void _onTapCustomer(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/chat');
      case 2:
        context.go('/history');
      case 3:
        context.go('/reviews');
      case 4:
        context.go('/profile');
    }
  }

  void _onTapProfessional(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/availability');
      case 2:
        context.go('/chat');
      case 3:
        context.go('/clients');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isProfessional = user?.isProfessional ?? false;

    final tr = ref.watch(translationsProvider);
    final tabs = isProfessional
        ? _buildProfessionalTabs(tr)
        : _buildCustomerTabs(tr);
    final currentIdx = isProfessional
        ? _currentIndexProfessional(context)
        : _currentIndexCustomer(context);
    final onTap = isProfessional ? _onTapProfessional : _onTapCustomer;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                );
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIdx,
            onDestinationSelected: (i) => onTap(context, i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 72,
            destinations: tabs
                .map(
                  (t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon),
                    label: t.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Profile / Account screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) async {
    final t = ref.read(translationsProvider);
    final firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          t.editProfile,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameCtrl,
                  decoration: InputDecoration(labelText: t.firstName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: InputDecoration(labelText: t.lastName),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: t.mobile),
                  keyboardType: TextInputType.phone,
                ),
                if (user?.isProfessional == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: t.descriptionOptional,
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(t.saveChanges),
          ),
        ],
      ),
    );

    if (shouldSave != true ||
        user?.coId == null ||
        user.coId.toString().isEmpty) {
      return;
    }

    try {
      await ref.read(accountRepositoryProvider).updateAccount(user.coId, {
        'co_first_name': firstNameCtrl.text.trim(),
        'co_last_name': lastNameCtrl.text.trim(),
        'co_mobile': phoneCtrl.text.trim(),
      });

      if (user.isProfessional == true && descCtrl.text.trim().isNotEmpty) {
        await ref.read(accountRepositoryProvider).updateProDescription(
          user.coId,
          {'co_description': descCtrl.text.trim()},
        );
      }

      await ref.read(authStateProvider.notifier).fetchUser();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.profileUpdated),
          backgroundColor: AppColors.online,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.profileUpdateFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isProfessional = user?.isProfessional ?? false;
    final agency = ref.watch(agencyProvider);
    final t = ref.watch(translationsProvider);
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Fetch dynamic stats from backend
    final historyAsync = ref.watch(
      isProfessional ? professionalHistoryProvider : customerHistoryProvider,
    );
    final reviewsAsync = ref.watch(
      isProfessional ? professionalReviewsProvider : customerReviewsProvider,
    );
    final pricingAsync = isProfessional
        ? const AsyncValue<Map<String, dynamic>>.data(<String, dynamic>{})
        : ref.watch(customerPricingProvider);

    return GradientScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header with avatar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Avatar
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosePink.withValues(alpha: 0.4),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.jost(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      name.isEmpty ? t.guestUser : name,
                      style: GoogleFonts.jost(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Stats cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: isProfessional
                    ? historyAsync.when(
                        loading: () => Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.history,
                                value: '--',
                                label: t.sessionsLabel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.access_time,
                                value: '--',
                                label: t.totalTime,
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.history,
                                value: '0',
                                label: t.sessionsLabel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.access_time,
                                value: '0h',
                                label: t.totalTime,
                              ),
                            ),
                          ],
                        ),
                        data: (history) {
                          final sessionCount = history.length;
                          double totalMinutes = 0;
                          for (final item in history) {
                            final itemMap = item as Map<String, dynamic>;
                            final durationStr =
                                itemMap['se_duration']?.toString() ?? '';
                            final minutes = _parseDuration(durationStr);
                            totalMinutes += minutes;
                          }
                          final totalHours = (totalMinutes / 60)
                              .toStringAsFixed(1);

                          return reviewsAsync.when(
                            loading: () => Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.history,
                                    value: sessionCount.toString(),
                                    label: t.sessionsLabel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.access_time,
                                    value: '${totalHours}h',
                                    label: t.totalTime,
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.history,
                                    value: sessionCount.toString(),
                                    label: t.sessionsLabel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.access_time,
                                    value: '${totalHours}h',
                                    label: t.totalTime,
                                  ),
                                ),
                              ],
                            ),
                            data: (reviews) {
                              double avgRating = 0;
                              if (reviews.isNotEmpty) {
                                double totalRating = 0;
                                for (final review in reviews) {
                                  final reviewMap =
                                      review as Map<String, dynamic>;
                                  final rating = reviewMap['re_rating'] as num?;
                                  if (rating != null) {
                                    totalRating += rating.toDouble();
                                  }
                                }
                                avgRating = totalRating / reviews.length;
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.history,
                                      value: sessionCount.toString(),
                                      label: t.sessionsLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.star,
                                      value: avgRating > 0
                                          ? avgRating.toStringAsFixed(1)
                                          : 'N/A',
                                      label: t.rating,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.access_time,
                                      value: '${totalHours}h',
                                      label: t.totalTime,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      )
                    : historyAsync.when(
                        loading: () => _CustomerStatsGrid(
                          creditValue: '--',
                          phoneCount: '--',
                          videoCount: '--',
                          chatCount: '--',
                          creditLabel: t.credit,
                          phoneLabel: t.phoneCall,
                          videoLabel: t.videoCall,
                          chatLabel: t.textChat,
                        ),
                        error: (_, __) => _CustomerStatsGrid(
                          creditValue: '€0.00',
                          phoneCount: '0',
                          videoCount: '0',
                          chatCount: '0',
                          creditLabel: t.credit,
                          phoneLabel: t.phoneCall,
                          videoLabel: t.videoCall,
                          chatLabel: t.textChat,
                        ),
                        data: (history) {
                          final counts = _customerSessionTypeCounts(history);
                          final credit = pricingAsync.when(
                            data: _extractCustomerCredit,
                            loading: () => null,
                            error: (_, __) => null,
                          );

                          return _CustomerStatsGrid(
                            creditValue: _formatEuro(credit),
                            phoneCount: '${counts.phone}',
                            videoCount: '${counts.video}',
                            chatCount: '${counts.chat}',
                            creditLabel: t.credit,
                            phoneLabel: t.phoneCall,
                            videoLabel: t.videoCall,
                            chatLabel: t.textChat,
                          );
                        },
                      ),
              ),
            ),
            // ── Menu section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Text(
                  t.settings,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline,
                      title: t.editProfile,
                      subtitle: t.updateInfo,
                      onTap: () => _showEditProfileDialog(context, ref, user),
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: t.notifications,
                      subtitle: t.managePreferences,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t.notificationSettingsComingSoon,
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                            backgroundColor: AppColors.mediumPurple,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.payment_outlined,
                      title: t.paymentMethods,
                      subtitle: t.cardsBilling,
                      onTap: () => context.push('/pricing'),
                    ),
                  ],
                ),
              ),
            ),
            // ── Support section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  t.support,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.help_outline,
                      title: t.helpCenter,
                      subtitle: t.faqsGuides,
                      onTap: () {
                        _showAboutDialog(
                          context,
                          title: t.helpCenter,
                          content: t.helpCenterContent,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      title: t.privacyPolicy,
                      subtitle: t.readOurTerms,
                      onTap: () {
                        final termsUrl = agency?.termsUrl?.trim();
                        _showAboutDialog(
                          context,
                          title: t.privacyPolicy,
                          content: (termsUrl != null && termsUrl.isNotEmpty)
                              ? termsUrl
                              : t.privacyPolicyContent,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.info_outline,
                      title: t.aboutVoyanz,
                      subtitle: t.version100,
                      onTap: () {
                        final aboutText = agency?.aboutText?.trim();
                        _showAboutDialog(
                          context,
                          title: t.aboutVoyanz,
                          content: (aboutText != null && aboutText.isNotEmpty)
                              ? aboutText
                              : t.aboutVoyanzContent,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // ── Logout button ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t.logout,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parse duration string (e.g., "30 min", "1h 30min") and return total minutes
double _parseDuration(String durationStr) {
  if (durationStr.isEmpty) return 0;

  final str = durationStr.toLowerCase().trim();
  double totalMinutes = 0;

  // Match hours
  final hourMatch = RegExp(r'(\d+(?:\.\d+)?)\s*h(?:our)?s?').firstMatch(str);
  if (hourMatch != null) {
    totalMinutes += double.parse(hourMatch.group(1)!) * 60;
  }

  // Match minutes
  final minMatch = RegExp(
    r'(\d+(?:\.\d+)?)\s*m(?:in)?(?:ute)?s?',
  ).firstMatch(str);
  if (minMatch != null) {
    totalMinutes += double.parse(minMatch.group(1)!);
  }

  return totalMinutes;
}

/// Show an about dialog with title and content
void _showAboutDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  final t = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(translationsProvider);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceCard.withValues(alpha: 0.95),
      title: Text(
        title,
        style: GoogleFonts.jost(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        content,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            t.close,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.rosePink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: AppColors.rosePink, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jost(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerStatsGrid extends StatelessWidget {
  final String creditValue;
  final String phoneCount;
  final String videoCount;
  final String chatCount;
  final String creditLabel;
  final String phoneLabel;
  final String videoLabel;
  final String chatLabel;

  const _CustomerStatsGrid({
    required this.creditValue,
    required this.phoneCount,
    required this.videoCount,
    required this.chatCount,
    required this.creditLabel,
    required this.phoneLabel,
    required this.videoLabel,
    required this.chatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                value: creditValue,
                label: creditLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.phone_in_talk_outlined,
                value: phoneCount,
                label: phoneLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.videocam_outlined,
                value: videoCount,
                label: videoLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.chat_bubble_outline,
                value: chatCount,
                label: chatLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionTypeCounts {
  final int phone;
  final int video;
  final int chat;

  const _SessionTypeCounts({
    required this.phone,
    required this.video,
    required this.chat,
  });
}

_SessionTypeCounts _customerSessionTypeCounts(List<dynamic> history) {
  var phone = 0;
  var video = 0;
  var chat = 0;

  for (final item in history) {
    if (item is! Map<String, dynamic>) continue;
    final rawType =
        (item['se_type'] ??
                item['session_type'] ??
                item['typecall'] ??
                item['type'])
            ?.toString()
            .trim()
            .toLowerCase();

    if (rawType == null || rawType.isEmpty) continue;
    if (rawType.contains('phone')) {
      phone++;
      continue;
    }
    if (rawType.contains('video')) {
      video++;
      continue;
    }
    if (rawType.contains('chat') || rawType.contains('text')) {
      chat++;
      continue;
    }
  }

  return _SessionTypeCounts(phone: phone, video: video, chat: chat);
}

double? _extractCustomerCredit(Map<String, dynamic> pricing) {
  const keys = [
    'credit',
    'co_credit',
    'customer_credit',
    'balance',
    'wallet',
    'amount',
  ];

  for (final key in keys) {
    final raw = pricing[key];
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed != null) return parsed;
  }

  return null;
}

String _formatEuro(double? value) {
  if (value == null) return '--';
  return '€${value.toStringAsFixed(2)}';
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.accent.scale(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.rosePink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
