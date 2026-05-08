import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/l10n/language_switcher.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/sessions/screens/incoming_call_dialog.dart';

/// Dashboard screen for professionals showing upcoming sessions and stats.
class ProfessionalDashboardScreen extends ConsumerStatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  ConsumerState<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends ConsumerState<ProfessionalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    // Clean up WebSocket when leaving the screen
    // Note: Don't disconnect here; keep it alive for background notifications
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Fetch professional history (sessions)
    final historyAsync = ref.watch(professionalHistoryProvider);

    // Fetch professional reviews
    final reviewsAsync = ref.watch(professionalReviewsProvider);
    final t = ref.watch(translationsProvider);
    final name = _displayName(user, professionalFallback: t.professional);

    // Listen for incoming calls and show dialog
    ref.listen(incomingCallProvider, (previous, next) {
      if (next != null && (previous == null || previous.customerId != next.customerId)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const IncomingCallDialog(),
        );
      }
    });

    // Listen for session started event and navigate to session
    ref.listen(sessionStartedProvider, (previous, next) {
      if (next != null) {
        _navigateToSession(context, next);
        ref.read(sessionStartedProvider.notifier).clear();
      }
    });

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.dashboard,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [LanguageSwitcherButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Welcome section ──
            SliverToBoxAdapter(
              child: _RevealIn(
                delayMs: 20,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _DashboardHeroCard(
                    name: name,
                    subtitle: t.yourProDashboard,
                    onOpenSlots: () => context.go('/availability'),
                    onOpenChat: () => context.go('/chat'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            SliverToBoxAdapter(
              child: _RevealIn(
                delayMs: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rosePink.withValues(alpha: 0.14),
                          AppColors.mediumPurple.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.mediumPurple.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          color: AppColors.rosePink,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Fresh UI loaded: new hero, stronger cards, and a clearer navigation shell.',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── Stats section ──
            SliverToBoxAdapter(
              child: _RevealIn(
                delayMs: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: t.totalSessions,
                          value: historyAsync.when(
                            data: (items) => '${_validSessions(items).length}',
                            loading: () => '-',
                            error: (_, __) => '0',
                          ),
                          icon: Icons.videocam_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: t.avgRating,
                          value: reviewsAsync.when(
                            data: (items) {
                              final validItems = items
                                  .whereType<Map<String, dynamic>>()
                                  .toList();
                              if (validItems.isEmpty) return '0.0';
                              final totalRating = validItems.fold<double>(
                                0,
                                (sum, item) =>
                                    sum +
                                    (double.tryParse(
                                          item['re_rating']?.toString() ?? '',
                                        ) ??
                                        0),
                              );
                              final avg = (totalRating / validItems.length)
                                  .toStringAsFixed(1);
                              return avg;
                            },
                            loading: () => '-',
                            error: (_, __) => '0.0',
                          ),
                          icon: Icons.star_outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _RevealIn(
                delayMs: 130,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatCard(
                    title: t.upcomingSessions,
                    value: historyAsync.when(
                      data: (items) {
                        final upcoming = _validSessions(items).where((s) {
                          final status = (s['se_status']?.toString() ?? '')
                              .toLowerCase();
                          return status == 'pending' ||
                              status == 'calling' ||
                              status == 'inprogress';
                        }).length;
                        return '$upcoming';
                      },
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.schedule,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── Upcoming Sessions ──
            SliverToBoxAdapter(
              child: _RevealIn(
                delayMs: 180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    t.recentSessions,
                    style: GoogleFonts.jost(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          color: AppColors.surfaceDark.withValues(alpha: 0.62),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noSessionsYet,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final validItems = _validSessions(items).take(5).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final session = validItems[idx];
                    final clientName = _clientName(
                      session,
                      unknownFallback: t.unknown,
                    );
                    final rawType =
                        (session['se_type'] ?? session['session_type'])
                            ?.toString() ??
                        '';
                    final sessionType = _localizedDashboardType(rawType, t);
                    final rawStatus = session['se_status']?.toString() ?? '';
                    final localizedStatus = _localizedDashboardStatus(
                      rawStatus,
                      t,
                    );
                    final sessionDate =
                        (session['se_date'] ?? session['session_date'])
                            ?.toString() ??
                        '';

                    return _RevealIn(
                      delayMs: 220 + (idx * 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 7,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            color: AppColors.surfaceDark.withValues(
                              alpha: 0.58,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clientName,
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sessionType,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color:
                                          rawStatus.toLowerCase() == 'completed'
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : rawStatus.toLowerCase() ==
                                                'cancelled'
                                          ? Colors.red.withValues(alpha: 0.2)
                                          : AppColors.rosePink.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                    child: Text(
                                      localizedStatus,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            rawStatus.toLowerCase() ==
                                                'completed'
                                            ? Colors.green
                                            : rawStatus.toLowerCase() ==
                                                  'cancelled'
                                            ? Colors.red
                                            : AppColors.rosePink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (sessionDate.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sessionDate,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: validItems.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.failedLoadSessions,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _navigateToSession(
    BuildContext context,
    SessionStartedEvent event,
  ) {
    final seId = event.seId;
    final coId = event.coIdProfessional;
    final seType = event.seType.toLowerCase();

    // Navigate based on session type
    if (seType == 'video') {
      context.push('/video/$seId/$coId');
    } else if (seType == 'phone') {
      context.push('/session/phone/$seId/$coId');
    } else if (seType == 'chat') {
      context.push('/session/chat/$seId/$coId');
    }
  }
}

class _DashboardHeroCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onOpenSlots;
  final VoidCallback onOpenChat;

  const _DashboardHeroCard({
    required this.name,
    required this.subtitle,
    required this.onOpenSlots,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceCard.withValues(alpha: 0.95),
            AppColors.surfaceElevated.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name',
            style: GoogleFonts.jost(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenSlots,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Manage Slots'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rosePink,
                    foregroundColor: AppColors.deepIndigo,
                    textStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Messages'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.borderSubtle.withValues(alpha: 0.85),
                    ),
                    textStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      duration: Duration(milliseconds: 380 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

String _displayName(
  dynamic user, {
  String professionalFallback = 'Professional',
}) {
  if (user == null) return professionalFallback;
  final full = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  if (full.isNotEmpty) return full;
  final email = (user.email ?? '').toString();
  if (email.contains('@')) return email.split('@').first;
  return professionalFallback;
}

List<Map<String, dynamic>> _validSessions(List<dynamic> items) {
  return items.whereType<Map<String, dynamic>>().toList();
}

String _clientName(
  Map<String, dynamic> session, {
  String unknownFallback = 'Unknown',
}) {
  return (session['co_fullname'] ??
              session['co_display_name'] ??
              session['customer_name'] ??
              session['client_name'])
          ?.toString() ??
      unknownFallback;
}

String _localizedDashboardType(String type, dynamic t) {
  switch (type.toLowerCase()) {
    case 'phone':
      return t.phoneCall;
    case 'video':
      return t.videoCall;
    case 'chat':
      return t.textChat;
    default:
      return type.isEmpty ? t.session : type;
  }
}

String _localizedDashboardStatus(String status, dynamic t) {
  switch (status.toLowerCase()) {
    case 'completed':
      return t.completed;
    case 'cancelled':
      return t.cancelled;
    case 'pending':
      return t.pending;
    default:
      return status;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceCard.withValues(alpha: 0.86),
            AppColors.surfaceElevated.withValues(alpha: 0.74),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rosePink.withValues(alpha: 0.18),
                ),
                child: Icon(icon, size: 14, color: AppColors.rosePink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jost(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
