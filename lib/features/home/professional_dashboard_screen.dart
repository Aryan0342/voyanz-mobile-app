import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
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
      if (next != null &&
          (previous == null || previous.customerId != next.customerId)) {
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
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Welcome section ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _DashboardHeroCard(
                    name: name,
                    subtitle: t.yourProDashboard,
                    onOpenSlots: () => context.go('/availability'),
                    onOpenChat: () => context.go('/chat'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Stats section ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 360),
                offset: const Offset(0, 14),
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
              child: SoftEntrance(
                duration: const Duration(milliseconds: 400),
                offset: const Offset(0, 14),
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Recent Sessions ──
            SliverToBoxAdapter(
              child: SoftEntrance(
                duration: const Duration(milliseconds: 440),
                offset: const Offset(0, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    t.recentSessions,
                    style: GoogleFonts.jost(
                      fontSize: 20,
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
                      child: AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mediumPurple.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.inbox_outlined,
                                size: 28,
                                color: AppColors.mediumPurple,
                              ),
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

                    final statusColor = rawStatus.toLowerCase() == 'completed'
                        ? AppColors.success
                        : rawStatus.toLowerCase() == 'cancelled'
                            ? AppColors.error
                            : AppColors.mediumPurple;
                    final statusIcon = rawStatus.toLowerCase() == 'completed'
                        ? Icons.check_circle_outline
                        : rawStatus.toLowerCase() == 'cancelled'
                            ? Icons.cancel_outlined
                            : Icons.schedule;

                    final typeIcon = rawType.toLowerCase() == 'phone'
                        ? Icons.phone_in_talk_outlined
                        : rawType.toLowerCase() == 'chat'
                            ? Icons.chat_bubble_outline
                            : Icons.videocam_outlined;

                    return SoftEntrance(
                      duration: Duration(milliseconds: 320 + (idx * 40)),
                      offset: const Offset(0, 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.mediumPurple.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      size: 20,
                                      color: AppColors.mediumPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clientName,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
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
                                  const SizedBox(width: 8),
                                  StatusPill(
                                    label: localizedStatus,
                                    color: statusColor,
                                    icon: statusIcon,
                                  ),
                                ],
                              ),
                              if (sessionDate.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sessionDate,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
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
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mediumPurple),
                  ),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 44,
                          color: AppColors.error,
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _navigateToSession(BuildContext context, SessionStartedEvent event) {
    final seId = event.seId;
    final coId = event.coIdCustomer.isNotEmpty
        ? event.coIdCustomer
        : event.coIdProfessional;
    final seType = event.seType.toLowerCase();

    // Navigate based on session type
    if (seType == 'video') {
      context.push('/video/$seId/$coId');
    } else if (seType == 'phone') {
      context.push('/session/phone/$seId/$coId');
    } else if (seType == 'chat') {
      final chgrId = event.chgrId;
      if (chgrId != null && chgrId.isNotEmpty) {
        context.push('/chat/$chgrId');
        return;
      }
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
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accent,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: GoogleFonts.jost(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: onOpenSlots,
                  height: 46,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Manage Slots'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SoftPress(
                  onTap: onOpenChat,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Messages',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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
    return SoftEntrance(
      duration: Duration(milliseconds: 340 + delayMs),
      offset: const Offset(0, 12),
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
    return AppCard(
      padding: const EdgeInsets.all(16),
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.mediumPurple.withValues(alpha: 0.11),
                ),
                child: Icon(icon, size: 15, color: AppColors.mediumPurple),
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
