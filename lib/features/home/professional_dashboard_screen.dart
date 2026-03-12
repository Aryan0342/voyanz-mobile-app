import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/l10n/language_switcher.dart';

/// Dashboard screen for professionals showing upcoming sessions and stats.
class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Fetch professional history (sessions)
    final historyAsync = ref.watch(professionalHistoryProvider);

    // Fetch professional reviews
    final reviewsAsync = ref.watch(professionalReviewsProvider);
    final t = ref.watch(translationsProvider);
    final name = _displayName(user, professionalFallback: t.professional);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSwitcherButton(), SizedBox(width: 8)],
        title: Text(
          t.dashboard,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Welcome section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.welcomeBackName(name),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.yourProDashboard,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        icon: Icons.star_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Upcoming Sessions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  t.recentSessions,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          color: AppColors.surfaceDark.withValues(alpha: 0.5),
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
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          color: AppColors.surfaceDark.withValues(alpha: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clientName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sessionType,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color:
                                        rawStatus.toLowerCase() == 'completed'
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : rawStatus.toLowerCase() == 'cancelled'
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : AppColors.rosePink.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  child: Text(
                                    localizedStatus,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          rawStatus.toLowerCase() == 'completed'
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.3),
        ),
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
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
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
