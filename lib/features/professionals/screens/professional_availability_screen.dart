import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
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
                'Add Availability Slot',
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
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: days
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
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
                      decoration: const InputDecoration(
                        labelText: 'Start Time (HH:mm)',
                        hintText: '09:00',
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Start time is required';
                        final ok = RegExp(
                          r'^([01]\d|2[0-3]):[0-5]\d$',
                        ).hasMatch(value);
                        if (!ok) return 'Use 24h format, e.g. 09:00';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: timeEndCtrl,
                      decoration: const InputDecoration(
                        labelText: 'End Time (HH:mm)',
                        hintText: '10:00',
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null; // optional
                        final ok = RegExp(
                          r'^([01]\d|2[0-3]):[0-5]\d$',
                        ).hasMatch(value);
                        if (!ok) return 'Use 24h format, e.g. 10:00';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Save'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability slot added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add slot: $e')));
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
    final availabilityAsync = ref.watch(professionalDisponibilitiesProvider);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage Slots',
          style: GoogleFonts.jost(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(professionalDisponibilitiesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
        label: const Text('Add Slot'),
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
                  'Failed to load availability',
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
                  label: const Text('Retry'),
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
                    'No slots added yet',
                    style: GoogleFonts.jost(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "Add Slot" to set your availability.',
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surfaceCard.withValues(alpha: 0.75),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.day,
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: row.slots
                          .map(
                            (slot) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppColors.rosePink.withValues(
                                  alpha: 0.17,
                                ),
                                border: Border.all(
                                  color: AppColors.rosePink.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
  final List<String> slots;

  const _AvailabilityRow({required this.day, required this.slots});
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
        rows.add(_AvailabilityRow(day: day, slots: [timeLabel]));
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

    final slots = <String>[];
    if (rawSlots is List) {
      for (final slot in rawSlots) {
        final text = slot?.toString().trim() ?? '';
        if (text.isNotEmpty) slots.add(text);
      }
    } else {
      final single =
          (item['slot'] ?? item['time'] ?? item['hour'])?.toString().trim() ??
          '';
      if (single.isNotEmpty) slots.add(single);
    }

    if (slots.isNotEmpty) rows.add(_AvailabilityRow(day: day, slots: slots));
  }

  rows.sort((a, b) => a.day.compareTo(b.day));
  return rows;
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
