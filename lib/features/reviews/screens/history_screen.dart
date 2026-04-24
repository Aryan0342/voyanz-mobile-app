import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/sessions/models/session_type.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final bool isProfessional;

  const HistoryScreen({super.key, this.isProfessional = false});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';

  String _normalizedStatus(Map<String, dynamic> item) {
    final raw = (item['se_status'] ?? item['status'] ?? item['state'] ?? '')
        .toString()
        .toLowerCase();
    return _canonicalStatus(raw);
  }

  bool _isSessionItem(Map<String, dynamic> item) {
    final explicitType = (item['type'] ?? '').toString().toLowerCase();
    if (explicitType.isNotEmpty) {
      return explicitType == 'session';
    }

    // No explicit type returned: infer from common session keys.
    return item.containsKey('se_id') ||
        item.containsKey('se_status') ||
        item.containsKey('se_type') ||
        item.containsKey('se_date');
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_selectedFilter == 'All') return true;
    final status = _normalizedStatus(item);
    if (_selectedFilter == 'Cancelled') {
      return status == 'cancelled' || status == 'canceled';
    }
    return status == _selectedFilter.toLowerCase();
  }

  Map<String, int> _statusCounts(List<Map<String, dynamic>> items) {
    final counts = <String, int>{'completed': 0, 'cancelled': 0, 'pending': 0};
    for (final item in items) {
      final status = _normalizedStatus(item);
      if (status == 'completed') counts['completed'] = counts['completed']! + 1;
      if (status == 'cancelled' || status == 'canceled') {
        counts['cancelled'] = counts['cancelled']! + 1;
      }
      if (status == 'pending') counts['pending'] = counts['pending']! + 1;
    }
    return counts;
  }

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
                .where(_isSessionItem)
                .toList();

            if (validItems.isEmpty) {
              return _EmptyState();
            }

            final filteredItems = validItems.where(_matchesFilter).toList();
            final counts = _statusCounts(validItems);

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
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _HistoryStat(
                                  label: t.totalSessions,
                                  value: '${validItems.length}',
                                  color: AppColors.mediumPurple,
                                  icon: Icons.history,
                                ),
                                const SizedBox(width: 10),
                                _HistoryStat(
                                  label: t.completed,
                                  value: '${counts['completed'] ?? 0}',
                                  color: AppColors.success,
                                  icon: Icons.check_circle_outline,
                                ),
                                const SizedBox(width: 10),
                                _HistoryStat(
                                  label: t.pending,
                                  value: '${counts['pending'] ?? 0}',
                                  color: AppColors.warning,
                                  icon: Icons.schedule,
                                ),
                              ],
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

  String _value(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final rawType = _value(item, const [
      'se_type',
      'type_call',
      'call_type',
      'type',
    ]);
    final dateRaw = _value(item, const [
      'se_date',
      'date',
      'created_at',
      'start_at',
    ]);
    final rawStatus = _value(item, const ['se_status', 'status', 'state']);
    final normalizedType = normalizeSessionType(rawType);
    final normalizedStatus = _canonicalStatus(rawStatus.toLowerCase());
    final date = _formatHistoryDate(dateRaw);
    final durationValue = _value(item, const [
      'se_duration',
      'duration',
      'call_duration',
    ]);
    final duration = durationValue.isEmpty ? '--' : durationValue;
    final counterpart = _value(item, const [
      'co_fullname',
      'co_name',
      'name',
      'customer_name',
    ]);
    final sessionId = _value(item, const ['se_id', 'id']);

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
                  gradient: _typeGradient(normalizedType),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor(
                        normalizedStatus,
                      ).withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _typeIcon(normalizedType),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedSessionType(
                        normalizedType ??
                            (rawType.isEmpty ? 'session' : rawType),
                        t,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (counterpart.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        counterpart,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                  color: _statusColor(normalizedStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusColor(
                      normalizedStatus,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _localizedStatus(normalizedStatus, t),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(normalizedStatus),
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
                if (sessionId.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.badge_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#$sessionId',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
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
      case 'inprogress':
      case 'accepted':
      case 'calling':
        return AppColors.mediumPurple;
      case 'cancelled':
      case 'canceled':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'phone':
        return Icons.phone_in_talk;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'video':
      default:
        return Icons.videocam;
    }
  }

  LinearGradient _typeGradient(String? type) {
    switch (type) {
      case 'phone':
        return LinearGradient(
          colors: [
            AppColors.mediumPurple.withValues(alpha: 0.9),
            AppColors.mediumPurple.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'chat':
        return LinearGradient(
          colors: [
            AppColors.rosePink.withValues(alpha: 0.9),
            AppColors.rosePink.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'video':
      default:
        return LinearGradient(
          colors: [
            AppColors.textMuted.withValues(alpha: 0.9),
            AppColors.textMuted.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
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
    case 'canceled':
      return t.cancelled;
    case 'pending':
      return t.pending;
    case 'accepted':
      return t.sessionStatusAcceptedLabel;
    case 'calling':
      return t.sessionStatusCallingLabel;
    case 'inprogress':
      return t.sessionStatusInProgressLabel;
    default:
      return t.unknown;
  }
}

String _canonicalStatus(String value) {
  if (value.isEmpty) return '';
  if (value == 'completed' ||
      value == 'done' ||
      value == 'finished' ||
      value == 'closed' ||
      value == 'success') {
    return 'completed';
  }
  if (value == 'cancelled' || value == 'canceled' || value == 'rejected') {
    return 'cancelled';
  }
  if (value == 'pending' || value == 'waiting') return 'pending';
  if (value == 'inprogress' || value == 'in_progress' || value == 'active') {
    return 'inprogress';
  }
  if (value == 'calling') return 'calling';
  if (value == 'accepted') return 'accepted';
  return value;
}

String _formatHistoryDate(String raw) {
  if (raw.isEmpty) return raw;
  final normalized = raw.replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return raw;
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  final hh = parsed.hour.toString().padLeft(2, '0');
  final min = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.year}-$mm-$dd $hh:$min';
}

class _HistoryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HistoryStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.jost(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
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
