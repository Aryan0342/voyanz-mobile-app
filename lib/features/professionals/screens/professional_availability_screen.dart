import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalAvailabilityScreen extends ConsumerStatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  ConsumerState<ProfessionalAvailabilityScreen> createState() =>
      _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState
    extends ConsumerState<ProfessionalAvailabilityScreen> {
  bool _submitting = false;

  Future<void> _showAddSlotDialog() async {
    final t = ref.read(translationsProvider);
    final dayCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final timeEndCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedDay = 'Monday';
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    dayCtrl.text = selectedDay;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              title: Text(
                t.addAvailabilitySlot,
                style: GoogleFonts.jost(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: InputDecoration(labelText: t.day),
                      items: days
                          .asMap()
                          .entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.value,
                              child: Text(t.days[entry.key]),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() => selectedDay = v);
                        dayCtrl.text = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: timeCtrl,
                      decoration: InputDecoration(
                        labelText: t.startTime,
                        hintText: t.startTimeHint,
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return t.startTimeRequired;
                        final ok = RegExp(
                          r'^([01]\d|2[0-3]):[0-5]\d$',
                        ).hasMatch(value);
                        if (!ok) return t.use24hFormat;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: timeEndCtrl,
                      decoration: InputDecoration(
                        labelText: t.endTime,
                        hintText: t.endTimeHint,
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null; // optional
                        final ok = RegExp(
                          r'^([01]\d|2[0-3]):[0-5]\d$',
                        ).hasMatch(value);
                        if (!ok) return t.use24hFormat;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit != true) return;

    setState(() => _submitting = true);
    try {
      final startTime = timeCtrl.text.trim();
      final endTime = timeEndCtrl.text.trim().isEmpty
          ? startTime
          : timeEndCtrl.text.trim();
      final payload = {
        'di_days': [_toFrenchDay(selectedDay)],
        'di_hour_from': startTime,
        'di_hour_to': endTime,
        'di_include': true,
      };

      await ref
          .read(professionalsRepositoryProvider)
          .createDisponibility(payload);

      final _ = await ref.refresh(professionalDisponibilitiesProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.slotAddedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.failedAddSlot('$e'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
      dayCtrl.dispose();
      timeCtrl.dispose();
      timeEndCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final availabilityAsync = ref.watch(professionalDisponibilitiesProvider);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.manageSlots,
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(professionalDisponibilitiesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: t.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _showAddSlotDialog,
        icon: _submitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(t.addSlot),
      ),
      body: availabilityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44),
                const SizedBox(height: 10),
                Text(
                  t.failedLoadAvailability,
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(professionalDisponibilitiesProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(t.retry),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final rows = _normalizeDisponibilities(items);

          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 54,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.noSlotsYet,
                    style: GoogleFonts.jost(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.tapAddSlot,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceCard.withValues(alpha: 0.90),
                      AppColors.surfaceCard.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.surfaceDark.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.rosePink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDayTitle(row.day, t),
                          style: GoogleFonts.jost(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...row.slots.map(
                      (slot) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.surfaceDark.withValues(alpha: 0.28),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.rosePink.withValues(alpha: 0.20),
                              ),
                              child: Text(
                                slot.timeLabel,
                                style: GoogleFonts.jost(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: slot.channels.isEmpty
                                  ? Text(
                                      'General',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: slot.channels
                                          .map(
                                            (channel) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(999),
                                                color: AppColors.rosePink.withValues(alpha: 0.15),
                                                border: Border.all(
                                                  color: AppColors.rosePink.withValues(alpha: 0.35),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _channelIcon(channel),
                                                    size: 14,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    channel,
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: rows.length,
          );
        },
      ),
    );
  }
}

class _AvailabilityRow {
  final String day;
  final List<_AvailabilitySlot> slots;

  const _AvailabilityRow({required this.day, required this.slots});
}

class _AvailabilitySlot {
  final String timeLabel;
  final List<String> channels;

  const _AvailabilitySlot({required this.timeLabel, required this.channels});
}

List<_AvailabilityRow> _normalizeDisponibilities(List<dynamic> items) {
  final rows = <_AvailabilityRow>[];

  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;

    // Current backend format: di_days array + di_hour_from / di_hour_to.
    final diDays = item['di_days'];
    final hourFrom = item['di_hour_from']?.toString().trim() ?? '';
    final hourTo = item['di_hour_to']?.toString().trim() ?? '';

    if (diDays is List && diDays.isNotEmpty) {
        final timeLabel =
          (hourFrom.isNotEmpty && hourTo.isNotEmpty && hourFrom != hourTo)
          ? '$hourFrom – $hourTo'
          : hourFrom.isNotEmpty
          ? hourFrom
          : '?';

      for (final dayRaw in diDays) {
        final day = _toEnglishDay(dayRaw?.toString() ?? '');
        rows.add(
          _AvailabilityRow(
            day: day,
            slots: [
              _AvailabilitySlot(timeLabel: timeLabel, channels: const []),
            ],
          ),
        );
      }
      continue;
    }

    // Fallback: legacy format with day + slots list.
    final day =
        (item['day'] ?? item['di_day'] ?? item['weekday'] ?? item['date'])
            ?.toString() ??
        'Unknown day';

    final rawSlots =
        item['slots'] ?? item['di_slots'] ?? item['times'] ?? item['hours'];

    final slots = <_AvailabilitySlot>[];
    if (rawSlots is List) {
      for (final slot in rawSlots) {
        final parsed = _parseAvailabilitySlot(slot);
        if (parsed != null) slots.add(parsed);
      }
    } else {
      final single =
          (item['slot'] ?? item['time'] ?? item['hour'])?.toString().trim() ??
          '';
      if (single.isNotEmpty) {
        slots.add(_AvailabilitySlot(timeLabel: single, channels: const []));
      }
    }

    if (slots.isNotEmpty) rows.add(_AvailabilityRow(day: day, slots: slots));
  }

  final grouped = <String, List<_AvailabilitySlot>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.day, () => <_AvailabilitySlot>[]).addAll(row.slots);
  }

  final mergedRows = grouped.entries
      .map((e) => _AvailabilityRow(day: e.key, slots: e.value))
      .toList();

  mergedRows.sort((a, b) {
    final dateA = DateTime.tryParse(a.day);
    final dateB = DateTime.tryParse(b.day);
    if (dateA != null && dateB != null) return dateA.compareTo(dateB);
    return a.day.compareTo(b.day);
  });

  for (final row in mergedRows) {
    row.slots.sort((a, b) => _slotSortValue(a.timeLabel).compareTo(_slotSortValue(b.timeLabel)));
  }

  return mergedRows;
}

_AvailabilitySlot? _parseAvailabilitySlot(dynamic slot) {
  if (slot == null) return null;

  if (slot is String) {
    final text = slot.trim();
    final match = RegExp(r'^\[\s*([^,\]]+)\s*,\s*\[(.*)\]\s*\]$').firstMatch(text);
    if (match != null) {
      final time = match.group(1)?.trim() ?? '';
      final methodsRaw = match.group(2)?.trim() ?? '';
      final methods = methodsRaw
          .split(',')
          .map((e) => _normalizeChannelLabel(e))
          .where((e) => e.isNotEmpty)
          .toList();
      if (time.isNotEmpty || methods.isNotEmpty) {
        return _AvailabilitySlot(timeLabel: time.isNotEmpty ? time : '?', channels: methods);
      }
    }
    if (text.isEmpty) return null;
    return _AvailabilitySlot(timeLabel: text, channels: const []);
  }

  if (slot is Map) {
    final time =
        (slot['time'] ?? slot['hour'] ?? slot['start'])?.toString().trim() ??
        '';
    final methods = _readSessionMethods(
      slot['types'] ?? slot['methods'] ?? slot['channels'],
    );
    if (time.isNotEmpty || methods.isNotEmpty) {
      return _AvailabilitySlot(timeLabel: time.isNotEmpty ? time : '?', channels: methods);
    }
    final fallback = slot.toString().trim();
    if (fallback.isEmpty) return null;
    return _AvailabilitySlot(timeLabel: fallback, channels: const []);
  }

  if (slot is List) {
    if (slot.isEmpty) return null;

    final time = slot.first?.toString().trim() ?? '';
    final methods = slot.length > 1 ? _readSessionMethods(slot[1]) : <String>[];

    if (time.isNotEmpty || methods.isNotEmpty) {
      return _AvailabilitySlot(timeLabel: time.isNotEmpty ? time : '?', channels: methods);
    }
    final fallback = slot
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');
    if (fallback.isEmpty) return null;
    return _AvailabilitySlot(timeLabel: fallback, channels: const []);
  }

  final fallback = slot.toString().trim();
  if (fallback.isEmpty) return null;
  return _AvailabilitySlot(timeLabel: fallback, channels: const []);
}

List<String> _readSessionMethods(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => _normalizeChannelLabel(e?.toString() ?? ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  if (raw is String && raw.trim().isNotEmpty) {
    return [_normalizeChannelLabel(raw)];
  }

  return const [];
}

String _normalizeChannelLabel(String raw) {
  final value = raw.trim().toLowerCase();
  switch (value) {
    case 'call':
    case 'phone':
      return 'Phone';
    case 'chat':
    case 'message':
      return 'Chat';
    case 'video':
    case 'video_call':
    case 'video-call':
      return 'Video';
    default:
      return _capitalizeDay(raw.trim());
  }
}

int _slotSortValue(String label) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(label);
  if (match == null) return 9999;
  final hour = int.tryParse(match.group(1) ?? '') ?? 99;
  final minute = int.tryParse(match.group(2) ?? '') ?? 99;
  return (hour * 60) + minute;
}

String _formatDayTitle(String rawDay, AppTranslations t) {
  final date = DateTime.tryParse(rawDay);
  if (date == null) return _localizedDay(rawDay, t);

  final weekday = switch (date.weekday) {
    DateTime.monday => t.monday,
    DateTime.tuesday => t.tuesday,
    DateTime.wednesday => t.wednesday,
    DateTime.thursday => t.thursday,
    DateTime.friday => t.friday,
    DateTime.saturday => t.saturday,
    _ => t.sunday,
  };

  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$weekday  $dd/$mm/${date.year}';
}

IconData _channelIcon(String channel) {
  switch (channel.toLowerCase()) {
    case 'phone':
      return Icons.call_outlined;
    case 'chat':
      return Icons.chat_bubble_outline;
    case 'video':
      return Icons.videocam_outlined;
    default:
      return Icons.circle_outlined;
  }
}

String _toFrenchDay(String englishDay) {
  const map = {
    'Monday': 'lundi',
    'Tuesday': 'mardi',
    'Wednesday': 'mercredi',
    'Thursday': 'jeudi',
    'Friday': 'vendredi',
    'Saturday': 'samedi',
    'Sunday': 'dimanche',
  };
  return map[englishDay] ?? englishDay.toLowerCase();
}

String _toEnglishDay(String frenchDay) {
  const map = {
    'lundi': 'Monday',
    'mardi': 'Tuesday',
    'mercredi': 'Wednesday',
    'jeudi': 'Thursday',
    'vendredi': 'Friday',
    'samedi': 'Saturday',
    'dimanche': 'Sunday',
  };
  return map[frenchDay.toLowerCase()] ?? _capitalizeDay(frenchDay);
}

String _capitalizeDay(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _localizedDay(String englishDay, AppTranslations t) {
  switch (englishDay) {
    case 'Monday':
      return t.monday;
    case 'Tuesday':
      return t.tuesday;
    case 'Wednesday':
      return t.wednesday;
    case 'Thursday':
      return t.thursday;
    case 'Friday':
      return t.friday;
    case 'Saturday':
      return t.saturday;
    case 'Sunday':
      return t.sunday;
    default:
      return englishDay;
  }
}
