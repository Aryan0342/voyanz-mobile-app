import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/app_gradients.dart';
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
  static final List<Map<String, dynamic>> _pendingCreatedItems = [];

  Future<void> _showAddSlotDialog() => _showSlotDialog();

  Future<void> _showSlotDialog({
    String? diId,
    String? day,
    String? startTime,
    String? endTime,
  }) async {
    final t = ref.read(translationsProvider);
    final dayCtrl = TextEditingController(text: day ?? 'Monday');
    final timeCtrl = TextEditingController(text: startTime ?? '');
    final timeEndCtrl = TextEditingController(text: endTime ?? '');
    final formKey = GlobalKey<FormState>();

    String selectedDay = day ?? 'Monday';
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                decoration: const BoxDecoration(
                  gradient: AppGradients.accent,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        diId == null
                            ? Icons.add_alarm_rounded
                            : Icons.edit_calendar_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diId == null ? t.addAvailabilitySlot : t.editSlot,
                        style: GoogleFonts.jost(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
                        prefixIcon: const Icon(
                          Icons.wb_twilight_rounded,
                          size: 20,
                        ),
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
                        prefixIcon: const Icon(
                          Icons.dark_mode_rounded,
                          size: 20,
                        ),
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
              actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.cancel),
                ),
                GradientButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx, true);
                  },
                  height: 46,
                  width: 130,
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
      final weekday = _toBackendWeekday(selectedDay);
      final nextDate = _nextDateForWeekday(weekday);
      final dateWindow = _formatDate(nextDate);
      final payload = {
        'di_days': [weekday],
        'di_what': 'days',
        'di_how': ['period'],
        'di_date_from': dateWindow,
        'di_date_to': dateWindow,
        'di_hour_from': startTime,
        'di_hour_to': endTime,
        'di_include': true,
      };

      if (diId != null) {
        await ref
            .read(professionalsRepositoryProvider)
            .updateDisponibility(diId, payload);
        ref.invalidate(professionalDisponibilitiesPayloadProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.slotUpdatedSuccess)));
        }
        return;
      }

      await ref
          .read(professionalsRepositoryProvider)
          .createDisponibility(payload);

      if (mounted) {
        setState(() {
          _pendingCreatedItems.add({
            'di_days': [weekday],
            'di_what': 'days',
            'di_how': ['period'],
            'di_date_from': dateWindow,
            'di_date_to': dateWindow,
            'di_hour_from': startTime,
            'di_hour_to': endTime,
          });
        });
      }

      ref.invalidate(professionalDisponibilitiesPayloadProvider);
      final refreshed = await ref.read(
        professionalDisponibilitiesPayloadProvider.future,
      );

      final backendKeys = <String>{};
      final backendData = refreshed['data'];
      if (backendData is List) {
        for (final item in backendData) {
          if (item is! Map<String, dynamic>) continue;
          backendKeys.addAll(_extractIdentityKeysFromItem(item));
        }
      }
      if (mounted && backendKeys.isNotEmpty) {
        setState(() {
          _pendingCreatedItems.removeWhere((pending) {
            final pendingKeys = _extractIdentityKeysFromItem(pending);
            return pendingKeys.isNotEmpty &&
                pendingKeys.every(backendKeys.contains);
          });
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.slotAddedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.failedAddSlot('Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
      dayCtrl.dispose();
      timeCtrl.dispose();
      timeEndCtrl.dispose();
    }
  }

  void _editSlot(String day, _AvailabilitySlot slot) {
    final diId = slot.diId;
    if (diId == null) return;

    final range = _extractSlotRange(slot.timeLabel);
    final start = range.isEmpty
        ? slot.timeLabel.trim()
        : _minutesToTimeLabel(range.first);
    final end = range.length > 1
        ? _minutesToTimeLabel(range.last)
        : range.isEmpty
        ? ''
        : start;

    _showSlotDialog(
      diId: diId,
      day: day,
      startTime: start,
      endTime: range.length > 1 ? end : '',
    );
  }

  Future<void> _deleteSlot(_AvailabilitySlot slot) async {
    final t = ref.read(translationsProvider);
    final diId = slot.diId;
    if (diId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.error, AppColors.magentaRose],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.deleteSlot,
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            t.deleteSlotConfirm,
            style: GoogleFonts.manrope(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          GradientButton(
            onPressed: () => Navigator.pop(ctx, true),
            height: 46,
            width: 120,
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(professionalsRepositoryProvider)
          .deleteDisponibility(diId);
      ref.invalidate(professionalDisponibilitiesPayloadProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.slotDeletedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.failedDeleteSlot('Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final availabilityAsync = ref.watch(
      professionalDisponibilitiesPayloadProvider,
    );
    final topContentInset =
        MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return GradientScaffold(
      appBar: VoyanzAppBar(
        showBackButton: true,
        title: Text(
          t.manageSlots,
          style: GoogleFonts.jost(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          VoyanzAppBarIconButton(
            icon: Icons.refresh,
            onPressed: () =>
                ref.invalidate(professionalDisponibilitiesPayloadProvider),
            tooltip: t.refresh,
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _showAddSlotDialog,
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: _submitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          t.addSlot,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: availabilityAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mediumPurple),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 44,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
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
                    'An error occurred. Please try again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(
                      professionalDisponibilitiesPayloadProvider,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(t.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (payload) {
          final rawData = payload['data'];
          final nextData = payload['nextdisponibilities'];

          final rawItems = rawData is List ? rawData : const <dynamic>[];
          final nextItems = nextData is List ? nextData : const <dynamic>[];

          final mergedRawItems = [...rawItems, ..._pendingCreatedItems];
          final sourceItems = mergedRawItems.isNotEmpty ? mergedRawItems : nextItems;
          final rows = _normalizeDisponibilities(sourceItems);
          final totalSlots = rows.fold<int>(
            0,
            (sum, row) => sum + row.slots.length,
          );

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topContentInset, 20, 110),
            children: [
              SoftEntrance(
                duration: const Duration(milliseconds: 300),
                offset: const Offset(0, 14),
                child: _AvailabilityHero(
                  dayCount: rows.length,
                  slotCount: totalSlots,
                  t: t,
                ),
              ),
              const SizedBox(height: 24),
              if (rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    t.weeklySlots,
                    style: GoogleFonts.jost(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              if (rows.isEmpty)
                SoftEntrance(
                  duration: const Duration(milliseconds: 360),
                  offset: const Offset(0, 12),
                  child: _EmptyAvailabilityCard(onAdd: _showAddSlotDialog, t: t),
                ),
              ...rows.map((row) {
                final index = rows.indexOf(row);
                return SoftEntrance(
                  duration: Duration(milliseconds: 340 + (index * 30)),
                  offset: const Offset(0, 10),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _DayCard(
                      dayTitle: _formatDayTitle(row.day, t),
                      day: row.day,
                      slots: row.slots,
                      busy: _submitting,
                      t: t,
                      onEdit: (slot) => _editSlot(row.day, slot),
                      onDelete: _deleteSlot,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AvailabilityHero extends StatelessWidget {
  final int dayCount;
  final int slotCount;
  final AppTranslations t;

  const _AvailabilityHero({
    required this.dayCount,
    required this.slotCount,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final palette = [
      AppColors.mediumPurple,
      AppColors.magentaRose,
      AppColors.deepIndigo,
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette[0], palette[1], palette[2]],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mediumPurple.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
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
                      t.yourAvailability,
                      style: GoogleFonts.jost(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.availabilitySubtitle,
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(
                icon: Icons.event_available_rounded,
                value: '$dayCount',
                label: t.daysCount,
              ),
              const SizedBox(width: 12),
              _HeroStat(
                icon: Icons.access_time_rounded,
                value: '$slotCount',
                label: t.slotsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAvailabilityCard extends StatelessWidget {
  final VoidCallback onAdd;
  final AppTranslations t;

  const _EmptyAvailabilityCard({required this.onAdd, required this.t});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.mediumPurple, AppColors.magentaRose],
              ),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t.noSlotsYet,
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.tapAddSlot,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            onPressed: onAdd,
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(t.addSlot),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayTitle;
  final String day;
  final List<_AvailabilitySlot> slots;
  final bool busy;
  final AppTranslations t;
  final void Function(_AvailabilitySlot) onEdit;
  final void Function(_AvailabilitySlot) onDelete;

  const _DayCard({
    required this.dayTitle,
    required this.day,
    required this.slots,
    required this.busy,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _dayAccent(day);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.65)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _dayInitial(day),
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayTitle,
                      style: GoogleFonts.jost(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.slotsCountFor(slots.length),
                      style: GoogleFonts.manrope(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: slots.map((slot) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SlotRow(
                  slot: slot,
                  accent: accent,
                  busy: busy,
                  t: t,
                  onEdit: () => onEdit(slot),
                  onDelete: () => onDelete(slot),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final _AvailabilitySlot slot;
  final Color accent;
  final bool busy;
  final AppTranslations t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SlotRow({
    required this.slot,
    required this.accent,
    required this.busy,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slot.timeLabel,
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (slot.diId != null) ...[
            _RowAction(
              icon: Icons.edit_outlined,
              color: AppColors.textSecondary,
              tooltip: t.edit,
              onPressed: busy ? null : onEdit,
            ),
            const SizedBox(width: 4),
            _RowAction(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              tooltip: t.delete,
              onPressed: busy ? null : onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _RowAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

Color _dayAccent(String day) {
  final palette = [
    AppColors.mediumPurple,
    AppColors.magentaRose,
    AppColors.aqua,
    AppColors.gold,
    AppColors.deepIndigo,
    AppColors.rosePink,
    AppColors.online,
  ];
  final hash = day.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return palette[hash % palette.length];
}

String _dayInitial(String day) {
  final date = DateTime.tryParse(day);
  if (date != null) {
    const names = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[date.weekday];
  }
  return day.isEmpty ? '?' : day.substring(0, 1).toUpperCase();
}

List<int> _extractSlotRange(String label) {
  final matches = RegExp(r'(\d{1,2}):(\d{2})').allMatches(label).toList();
  if (matches.isEmpty) return const [];

  final minutes = matches
      .map(
        (m) =>
            ((int.tryParse(m.group(1) ?? '') ?? 0) * 60) +
            (int.tryParse(m.group(2) ?? '') ?? 0),
      )
      .toList();

  if (minutes.length == 1) return [minutes.first, minutes.first];
  return [minutes.first, minutes.last];
}

String _minutesToTimeLabel(int minutes) {
  final clamped = minutes.clamp(0, (23 * 60) + 59);
  final hour = (clamped ~/ 60).toString().padLeft(2, '0');
  final minute = (clamped % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _normalizeTimeValue(String raw) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw.trim());
  if (match == null) return raw.trim();
  final hour = (int.tryParse(match.group(1) ?? '') ?? 0)
      .clamp(0, 23)
      .toString()
      .padLeft(2, '0');
  final minute = (int.tryParse(match.group(2) ?? '') ?? 0)
      .clamp(0, 59)
      .toString()
      .padLeft(2, '0');
  return '$hour:$minute';
}

String _slotIdentity(String day, String start, String end) {
  final normalizedDay = _normalizeDayValue(day);
  final normalizedStart = _normalizeTimeValue(start);
  final normalizedEnd = _normalizeTimeValue(end);
  return '$normalizedDay|$normalizedStart|$normalizedEnd';
}

Set<String> _extractIdentityKeysFromItem(Map<String, dynamic> item) {
  final keys = <String>{};

  final diDays = _extractDayValues(item['di_days']);
  final from = item['di_hour_from']?.toString().trim() ?? '';
  final to = item['di_hour_to']?.toString().trim() ?? from;

  if (diDays.isNotEmpty && from.isNotEmpty) {
    for (final day in diDays) {
      keys.add(_slotIdentity(day, from, to));
    }
    return keys;
  }

  final day = _normalizeDayValue(
    item['day'] ?? item['di_day'] ?? item['weekday'] ?? item['date'],
  );

  final rawSlots =
      item['slots'] ?? item['di_slots'] ?? item['times'] ?? item['hours'];

  if (rawSlots is List) {
    for (final slot in rawSlots) {
      final parsed = _parseAvailabilitySlot(slot);
      if (parsed == null) continue;
      final range = _extractSlotRange(parsed.timeLabel);
      if (range.isEmpty) continue;
      final start = _minutesToTimeLabel(range.first);
      final end = _minutesToTimeLabel(range.last);
      keys.add(_slotIdentity(day, start, end));
    }
  } else {
    final single =
        (item['slot'] ?? item['time'] ?? item['hour'])?.toString().trim() ?? '';
    if (single.isNotEmpty) {
      final range = _extractSlotRange(single);
      if (range.isNotEmpty) {
        final start = _minutesToTimeLabel(range.first);
        final end = _minutesToTimeLabel(range.last);
        keys.add(_slotIdentity(day, start, end));
      }
    }
  }

  return keys;
}

List<String> _extractDayValues(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    final bracketMatch = RegExp(r'^\[(.*)\]$').firstMatch(text);
    final normalized = (bracketMatch?.group(1) ?? text)
        .replaceAll('"', '')
        .replaceAll("'", '');

    return normalized
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  return const [];
}

class _AvailabilityRow {
  final String day;
  final List<_AvailabilitySlot> slots;

  const _AvailabilityRow({required this.day, required this.slots});
}

class _AvailabilitySlot {
  final String timeLabel;
  final List<String> channels;
  final String? diId;

  const _AvailabilitySlot({
    required this.timeLabel,
    required this.channels,
    this.diId,
  });
}

List<_AvailabilityRow> _normalizeDisponibilities(List<dynamic> items) {
  final rows = <_AvailabilityRow>[];

  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;

    // Current backend format: di_days array + di_hour_from / di_hour_to.
    final diDays = _extractDayValues(item['di_days']);
    final hourFrom = item['di_hour_from']?.toString().trim() ?? '';
    final hourTo = item['di_hour_to']?.toString().trim() ?? '';
    final diId = item['di_id']?.toString();

    if (diDays.isNotEmpty) {
      final timeLabel =
          (hourFrom.isNotEmpty && hourTo.isNotEmpty && hourFrom != hourTo)
          ? '$hourFrom â€“ $hourTo'
          : hourFrom.isNotEmpty
          ? hourFrom
          : '?';

      for (final dayRaw in diDays) {
        final day = _normalizeDayValue(dayRaw);
        rows.add(
          _AvailabilityRow(
            day: day,
            slots: [
              _AvailabilitySlot(
                timeLabel: timeLabel,
                channels: const [],
                diId: diId,
              ),
            ],
          ),
        );
      }
      continue;
    }

    // Fallback: legacy format with day + slots list.
    final day = _normalizeDayValue(
      item['day'] ?? item['di_day'] ?? item['weekday'] ?? item['date'],
    );

    final rawSlots =
        item['slots'] ?? item['di_slots'] ?? item['times'] ?? item['hours'];

    final slots = <_AvailabilitySlot>[];
    if (rawSlots is List) {
      for (final slot in rawSlots) {
        final parsed = _parseAvailabilitySlot(slot);
        if (parsed != null) {
          slots.add(_copyWithDiId(parsed, diId));
        }
      }
    } else {
      final single =
          (item['slot'] ?? item['time'] ?? item['hour'])?.toString().trim() ??
          '';
      if (single.isNotEmpty) {
        slots.add(
          _AvailabilitySlot(timeLabel: single, channels: const [], diId: diId),
        );
      }
    }

    if (slots.isEmpty && hourFrom.isNotEmpty) {
      final timeLabel = (hourTo.isNotEmpty && hourTo != hourFrom)
          ? '$hourFrom â€“ $hourTo'
          : hourFrom;
      slots.add(
        _AvailabilitySlot(timeLabel: timeLabel, channels: const [], diId: diId),
      );
    }

    if (slots.isNotEmpty) rows.add(_AvailabilityRow(day: day, slots: slots));
  }

  final grouped = <String, List<_AvailabilitySlot>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.day, () => <_AvailabilitySlot>[]).addAll(row.slots);
  }

  final mergedRows = grouped.entries.map((e) {
    final seen = <String>{};
    final uniqueSlots = <_AvailabilitySlot>[];
    for (final slot in e.value) {
      final key = '${slot.timeLabel}|${slot.channels.join(',')}|${slot.diId}';
      if (seen.add(key)) {
        uniqueSlots.add(slot);
      }
    }
    return _AvailabilityRow(day: e.key, slots: uniqueSlots);
  }).toList();

  mergedRows.sort((a, b) {
    final dateA = DateTime.tryParse(a.day);
    final dateB = DateTime.tryParse(b.day);
    if (dateA != null && dateB != null) return dateA.compareTo(dateB);
    return a.day.compareTo(b.day);
  });

  for (final row in mergedRows) {
    row.slots.sort(
      (a, b) =>
          _slotSortValue(a.timeLabel).compareTo(_slotSortValue(b.timeLabel)),
    );
  }

  return mergedRows;
}

_AvailabilitySlot? _parseAvailabilitySlot(dynamic slot) {
  if (slot == null) return null;

  if (slot is String) {
    final text = slot.trim();
    final match = RegExp(
      r'^\[\s*([^,\]]+)\s*,\s*\[(.*)\]\s*\]$',
    ).firstMatch(text);
    if (match != null) {
      final time = match.group(1)?.trim() ?? '';
      final methodsRaw = match.group(2)?.trim() ?? '';
      final methods = methodsRaw
          .split(',')
          .map((e) => _normalizeChannelLabel(e))
          .where((e) => e.isNotEmpty)
          .toList();
      if (time.isNotEmpty || methods.isNotEmpty) {
        return _AvailabilitySlot(
          timeLabel: time.isNotEmpty ? time : '?',
          channels: methods,
        );
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
      return _AvailabilitySlot(
        timeLabel: time.isNotEmpty ? time : '?',
        channels: methods,
      );
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
      return _AvailabilitySlot(
        timeLabel: time.isNotEmpty ? time : '?',
        channels: methods,
      );
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

_AvailabilitySlot _copyWithDiId(_AvailabilitySlot slot, String? diId) {
  if (slot.diId != null || diId == null) return slot;
  return _AvailabilitySlot(
    timeLabel: slot.timeLabel,
    channels: slot.channels,
    diId: diId,
  );
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

DateTime _nextDateForWeekday(int weekday) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final delta = (weekday - today.weekday + 7) % 7;
  return today.add(Duration(days: delta));
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _toBackendWeekday(String englishDay) {
  const map = {
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4,
    'Friday': 5,
    'Saturday': 6,
    'Sunday': 7,
  };
  return map[englishDay] ?? 1;
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

String _normalizeDayValue(dynamic raw) {
  if (raw == null) return 'Unknown day';

  if (raw is int) {
    return _weekdayFromNumber(raw) ?? raw.toString();
  }

  final text = raw.toString().trim();
  if (text.isEmpty) return 'Unknown day';

  final asInt = int.tryParse(text);
  if (asInt != null) {
    return _weekdayFromNumber(asInt) ?? text;
  }

  final date = DateTime.tryParse(text);
  if (date != null) {
    return text;
  }

  return _toEnglishDay(text);
}

String? _weekdayFromNumber(int value) {
  switch (value) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return null;
  }
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

