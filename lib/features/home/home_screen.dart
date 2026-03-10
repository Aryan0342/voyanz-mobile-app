import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

/// Bottom-navigation shell that wraps most authenticated screens.
/// Shows different tabs based on user role (customer vs professional).
class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  // Customer tabs
  static const _customerTabs = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    (icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
    (icon: Icons.star_outline, activeIcon: Icons.star, label: 'Reviews'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  // Professional tabs
  static const _professionalTabs = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Home',
    ),
    (
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Slots',
    ),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Clients'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
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

    final tabs = isProfessional ? _professionalTabs : _customerTabs;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Fetch dynamic stats from backend
    final historyAsync = ref.watch(
      (user?.isProfessional ?? false)
          ? professionalHistoryProvider
          : customerHistoryProvider,
    );
    final reviewsAsync = ref.watch(
      (user?.isProfessional ?? false)
          ? professionalReviewsProvider
          : customerReviewsProvider,
    );

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
                      name.isEmpty ? 'Guest User' : name,
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
                child: historyAsync.when(
                  loading: () => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.history,
                          value: '--',
                          label: 'Sessions',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.access_time,
                          value: '--',
                          label: 'Total Time',
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
                          label: 'Sessions',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.access_time,
                          value: '0h',
                          label: 'Total Time',
                        ),
                      ),
                    ],
                  ),
                  data: (history) {
                    // Calculate sessions count
                    final sessionCount = history.length;

                    // Calculate total duration
                    double totalMinutes = 0;
                    for (final item in history) {
                      final itemMap = item as Map<String, dynamic>;
                      final durationStr =
                          itemMap['se_duration']?.toString() ?? '';
                      final minutes = _parseDuration(durationStr);
                      totalMinutes += minutes;
                    }
                    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

                    return reviewsAsync.when(
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.history,
                              value: sessionCount.toString(),
                              label: 'Sessions',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.access_time,
                              value: '${totalHours}h',
                              label: 'Total Time',
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
                              label: 'Sessions',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.access_time,
                              value: '${totalHours}h',
                              label: 'Total Time',
                            ),
                          ),
                        ],
                      ),
                      data: (reviews) {
                        // Calculate average rating
                        double avgRating = 0;
                        if (reviews.isNotEmpty) {
                          double totalRating = 0;
                          for (final review in reviews) {
                            final reviewMap = review as Map<String, dynamic>;
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
                                label: 'Sessions',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star,
                                value: avgRating > 0
                                    ? avgRating.toStringAsFixed(1)
                                    : 'N/A',
                                label: 'Rating',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.access_time,
                                value: '${totalHours}h',
                                label: 'Total Time',
                              ),
                            ),
                          ],
                        );
                      },
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
                  'Settings',
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
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Edit Profile Coming Soon',
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
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage preferences',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notification Settings Coming Soon',
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
                      title: 'Payment Methods',
                      subtitle: 'Cards and billing',
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
                  'Support',
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
                      title: 'Help Center',
                      subtitle: 'FAQs and guides',
                      onTap: () {
                        _showAboutDialog(
                          context,
                          title: 'Help Center',
                          content:
                              'Frequently asked questions and guides will be available soon. '
                              'For immediate support, please contact our team.',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read our terms',
                      onTap: () {
                        _showAboutDialog(
                          context,
                          title: 'Privacy Policy',
                          content:
                              'Our privacy policy details how we collect, use, and protect your data. '
                              'Full policy will be available in the next update.',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTile(
                      icon: Icons.info_outline,
                      title: 'About Voyanz',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        _showAboutDialog(
                          context,
                          title: 'About Voyanz',
                          content:
                              'Voyanz - Your trusted platform for professional consultations.\n\n'
                              'Version: 1.0.0\n'
                              'Built with Flutter & ❤️',
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
                              'Log Out',
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
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
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
