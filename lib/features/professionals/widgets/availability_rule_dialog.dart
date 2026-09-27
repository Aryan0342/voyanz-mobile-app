import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';

/// One availability rule as `POST /web/1.0/disponibilities` takes it
/// (contract §10.4).
///
/// The app used to send a fixed shape — always available, always weekly,
/// always every channel, one weekday at a time, over a date window the
/// professional never chose. The website exposes all six options, so this
/// carries them.
class AvailabilityRule {
  /// `di_include` — false blocks the hours instead of offering them.
  final bool include;

  /// `di_what` — `days` (recurring weekdays), `dates` (weekdays within a
  /// period) or `date` (one calendar day).
  final String what;

  /// `di_days` — ISO weekday numbers, 1 = Monday.
  final List<int> days;

  /// `di_how` — `['period']` means every session type.
  final List<String> how;

  final String dateFrom;
  final String dateTo;
  final String hourFrom;
  final String hourTo;

  const AvailabilityRule({
    required this.include,
    required this.what,
    required this.days,
    required this.how,
    required this.dateFrom,
    required this.dateTo,
    required this.hourFrom,
    required this.hourTo,
  });

  Map<String, dynamic> toPayload() => {
    'di_include': include,
    'di_what': what,
    if (what != 'date') 'di_days': days,
    'di_how': how,
    'di_date_from': dateFrom,
    // For a single date the server sets the end itself, but sending it keeps
    // the payload valid either way.
    'di_date_to': what == 'date' ? dateFrom : dateTo,
    'di_hour_from': hourFrom,
    'di_hour_to': hourTo,
  };
}

/// Shows the rule editor. Returns null when cancelled.
Future<AvailabilityRule?> showAvailabilityRuleDialog(
  BuildContext context, {
  AvailabilityRule? initial,
}) {
  return showDialog<AvailabilityRule>(
    context: context,
    builder: (_) => _AvailabilityRuleDialog(initial: initial),
  );
}

class _AvailabilityRuleDialog extends ConsumerStatefulWidget {
  const _AvailabilityRuleDialog({this.initial});

  final AvailabilityRule? initial;

  @override
  ConsumerState<_AvailabilityRuleDialog> createState() =>
      _AvailabilityRuleDialogState();
}

class _AvailabilityRuleDialogState
    extends ConsumerState<_AvailabilityRuleDialog> {
  late bool _include;
  late String _what;
  late Set<int> _days;
  late Set<String> _channels; // phone / chat / video; empty means all
  late DateTime _from;
  late DateTime _to;
  late TimeOfDay _hourFrom;
  late TimeOfDay _hourTo;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final today = DateTime.now();
    _include = initial?.include ?? true;
    _what = initial?.what ?? 'days';
    _days = {...?initial?.days};
    if (_days.isEmpty) _days = {today.weekday};
    _channels = {...?initial?.how}..removeWhere((c) => c == 'period');
    _from = DateTime.tryParse(initial?.dateFrom ?? '') ?? today;
    _to =
        DateTime.tryParse(initial?.dateTo ?? '') ??
        today.add(const Duration(days: 30));
    _hourFrom = _parseTime(initial?.hourFrom) ?? const TimeOfDay(hour: 9, minute: 0);
    _hourTo = _parseTime(initial?.hourTo) ?? const TimeOfDay(hour: 18, minute: 0);
  }

  static TimeOfDay? _parseTime(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
  String _fmtDate(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
      _error = null;
    });
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _hourFrom : _hourTo,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _hourFrom = picked;
      } else {
        _hourTo = picked;
      }
      _error = null;
    });
  }

  void _submit(AppTranslations t) {
    if (_what != 'date' && _days.isEmpty) {
      setState(() => _error = t.selectDaysRequired);
      return;
    }
    if (_minutes(_hourTo) <= _minutes(_hourFrom)) {
      setState(() => _error = t.endBeforeStart);
      return;
    }
    if (_what == 'dates' && _to.isBefore(_from)) {
      setState(() => _error = t.dateToBeforeFrom);
      return;
    }

    // An empty or complete channel selection means "every session type", which
    // the backend spells `['period']`.
    final how = (_channels.isEmpty || _channels.length == 3)
        ? <String>['period']
        : _channels.toList();

    Navigator.of(context).pop(
      AvailabilityRule(
        include: _include,
        what: _what,
        days: (_days.toList()..sort()),
        how: how,
        dateFrom: _fmtDate(_from),
        dateTo: _fmtDate(_to),
        hourFrom: _fmtTime(_hourFrom),
        hourTo: _fmtTime(_hourTo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: Text(
        t.availabilityRule,
        style: GoogleFonts.jost(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _choices<bool>(
              label: '',
              values: const [true, false],
              labels: [t.availableLabel, t.unavailableLabel],
              selected: _include,
              onTap: (value) => setState(() {
                _include = value;
                _error = null;
              }),
            ),
            if (!_include) ...[
              const SizedBox(height: 6),
              Text(
                t.unavailableHint,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _label(t.repeatLabel),
            _choices<String>(
              label: '',
              values: const ['days', 'dates', 'date'],
              labels: [t.repeatWeekly, t.repeatPeriod, t.repeatSingleDate],
              selected: _what,
              onTap: (value) => setState(() {
                _what = value;
                _error = null;
              }),
            ),
            if (_what != 'date') ...[
              const SizedBox(height: 14),
              _label(t.selectDays),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (index) {
                  final iso = index + 1;
                  final isSelected = _days.contains(iso);
                  return FilterChip(
                    label: Text(t.days[index]),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      if (isSelected) {
                        _days.remove(iso);
                      } else {
                        _days.add(iso);
                      }
                      _error = null;
                    }),
                    backgroundColor: AppColors.surfaceElevated,
                    selectedColor: AppColors.brandPink.withValues(alpha: 0.28),
                    labelStyle: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 14),
            if (_what == 'date')
              _pickerRow(t.theDate, _fmtDate(_from), () => _pickDate(isFrom: true))
            else ...[
              _pickerRow(
                t.dateFrom,
                _fmtDate(_from),
                () => _pickDate(isFrom: true),
              ),
              const SizedBox(height: 8),
              _pickerRow(t.dateTo, _fmtDate(_to), () => _pickDate(isFrom: false)),
            ],
            const SizedBox(height: 8),
            _pickerRow(
              t.startTime,
              _fmtTime(_hourFrom),
              () => _pickTime(isFrom: true),
            ),
            const SizedBox(height: 8),
            _pickerRow(
              t.endTime,
              _fmtTime(_hourTo),
              () => _pickTime(isFrom: false),
            ),
            const SizedBox(height: 14),
            _label(t.channelsLabel),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _channelChip(t.allChannels, null),
                _channelChip(t.phoneCall, 'phone'),
                _channelChip(t.textChat, 'chat'),
                _channelChip(t.videoCall, 'video'),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.cancel,
            style: GoogleFonts.montserrat(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandPink),
          onPressed: () => _submit(t),
          child: Text(t.save),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textMuted),
    ),
  );

  Widget _choices<T>({
    required String label,
    required List<T> values,
    required List<String> labels,
    required T selected,
    required ValueChanged<T> onTap,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(values.length, (index) {
        final value = values[index];
        return ChoiceChip(
          label: Text(labels[index]),
          selected: selected == value,
          onSelected: (_) => onTap(value),
          backgroundColor: AppColors.surfaceElevated,
          selectedColor: AppColors.brandPink.withValues(alpha: 0.28),
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        );
      }),
    );
  }

  /// `null` is the "all session types" chip, which clears the selection.
  Widget _channelChip(String label, String? channel) {
    final isAll = channel == null;
    final isSelected = isAll ? _channels.isEmpty : _channels.contains(channel);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        if (isAll) {
          _channels.clear();
        } else if (isSelected) {
          _channels.remove(channel);
        } else {
          _channels.add(channel);
        }
        _error = null;
      }),
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.brandPink.withValues(alpha: 0.28),
      labelStyle: GoogleFonts.montserrat(
        fontSize: 11,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _pickerRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_calendar_outlined, size: 16),
          ],
        ),
      ),
    );
  }
}
