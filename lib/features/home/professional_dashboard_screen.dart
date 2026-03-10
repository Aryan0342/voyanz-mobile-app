import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

/// Dashboard screen for professionals showing upcoming sessions and stats.
class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    // Fetch professional history (sessions)
    final historyAsync = ref.watch(professionalHistoryProvider);

    // Fetch professional reviews
    final reviewsAsync = ref.watch(professionalReviewsProvider);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dashboard',
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
                      'Welcome back, $name',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your professional dashboard',
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
                        title: 'Total Sessions',
                        value: historyAsync.when(
                          data: (items) => '${items.length}',
                          loading: () => '-',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.videocam_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Avg Rating',
                        value: reviewsAsync.when(
                          data: (items) {
                            if (items.isEmpty) return '0.0';
                            final validItems = items
                                .where((item) => item is Map<String, dynamic>)
                                .cast<Map<String, dynamic>>()
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

            // ── Upcoming Sessions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Recent Sessions',
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
                              'No sessions yet',
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

                final validItems = items
                    .where((item) => item is Map<String, dynamic>)
                    .cast<Map<String, dynamic>>()
                    .toList()
                    .take(5)
                    .toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final session = validItems[idx];
                    final clientName =
                        session['co_fullname']?.toString() ?? 'Unknown';
                    final sessionType =
                        session['se_type']?.toString() ?? 'Session';
                    final sessionDate = session['se_date']?.toString() ?? '';
                    final status = session['se_status']?.toString() ?? '';

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
                                    color: status.toLowerCase() == 'completed'
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : status.toLowerCase() == 'cancelled'
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : AppColors.rosePink.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: status.toLowerCase() == 'completed'
                                          ? Colors.green
                                          : status.toLowerCase() == 'cancelled'
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
                        'Failed to load sessions',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
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
