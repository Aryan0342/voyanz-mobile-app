import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final bool isProfessional;

  const HistoryScreen({super.key, this.isProfessional = false});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final historyAsync = ref.watch(
      widget.isProfessional
          ? professionalHistoryProvider
          : customerHistoryProvider,
    );

    return GradientScaffold(
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.rosePink),
          ),
          error: (e, st) {
            return Center(
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
                    t.failedLoadHistory,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.errorMessage(e.toString()),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        widget.isProfessional
                            ? professionalHistoryProvider
                            : customerHistoryProvider,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(t.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rosePink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          data: (items) {
            if (items.isEmpty) {
              return _EmptyState();
            }

            // Filter items safely, excluding non-Map items
            final validItems = items
                .where((item) => item is Map<String, dynamic>)
                .cast<Map<String, dynamic>>()
                .toList();

            if (validItems.isEmpty) {
              return _EmptyState();
            }

            final filteredItems = _selectedFilter == 'All'
                ? validItems
                : validItems.where((item) {
                    final status =
                        item['se_status']?.toString().toLowerCase() ?? '';
                    return status == _selectedFilter.toLowerCase();
                  }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  widget.isProfessional
                      ? professionalHistoryProvider
                      : customerHistoryProvider,
                );
              },
              child: CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.sessionHistory,
                            style: GoogleFonts.jost(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.pastConsultations,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Filter chips ──
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _FilterChip(
                            label: t.all,
                            isSelected: _selectedFilter == 'All',
                            onTap: () =>
                                setState(() => _selectedFilter = 'All'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: t.completed,
                            isSelected: _selectedFilter == 'Completed',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Completed'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: t.cancelled,
                            isSelected: _selectedFilter == 'Cancelled',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Cancelled'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: t.pending,
                            isSelected: _selectedFilter == 'Pending',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Pending'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // ── Sessions list ──
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 56,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.noSessionsFound,
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
                        itemCount: filteredItems.length,
                        itemBuilder: (context, i) {
                          final item = filteredItems[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SessionCard(item: item),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.accent : null,
          color: isSelected
              ? null
              : AppColors.surfaceCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.rosePink.withValues(alpha: 0.5)
                : AppColors.mediumPurple.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const _SessionCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final type = item['se_type']?.toString() ?? 'Session';
    final date = item['se_date']?.toString() ?? '';
    final status = item['se_status']?.toString() ?? '';
    final duration = item['se_duration']?.toString() ?? '30 min';

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _statusGradient(status),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor(status).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(_statusIcon(status), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedSessionType(type, t),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusColor(status).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _localizedStatus(status, t),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.videocam;
    }
  }

  LinearGradient _statusGradient(String status) {
    final color = _statusColor(status);
    return LinearGradient(
      colors: [color, color.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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
            child: const Icon(Icons.history, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            t.noSessionsYetTitle,
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
              t.consultationHistoryWillAppear,
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

String _localizedStatus(String status, dynamic t) {
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

String _localizedSessionType(String type, dynamic t) {
  switch (type.toLowerCase()) {
    case 'phone':
    case 'phone call':
      return t.phoneCall;
    case 'video':
    case 'video call':
      return t.videoCall;
    case 'chat':
    case 'text chat':
      return t.textChat;
    case 'session':
      return t.consultation;
    default:
      return type;
  }
}
