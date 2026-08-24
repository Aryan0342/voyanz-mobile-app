import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/data/professionals_repository.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class FavoriteProfessionalsNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favorite_professionals';

  FavoriteProfessionalsNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey) ?? const [];
      if (stored.isEmpty) return;
      state = <String>{...stored};
    } catch (_) {}
  }

  void setFavorite(String coId, bool isFavorite) {
    final next = <String>{...state};
    if (isFavorite) {
      next.add(coId);
    } else {
      next.remove(coId);
    }
    state = next;
    _persist(next);
  }

  Future<void> _persist(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = ids.toList()..sort();
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }
}

final favoriteProfessionalIdsProvider =
    StateNotifierProvider<FavoriteProfessionalsNotifier, Set<String>>((ref) {
      return FavoriteProfessionalsNotifier();
    });

final professionalsDataSourceProvider = Provider<ProfessionalsDataSource>((
  ref,
) {
  return ProfessionalsDataSource(ref.watch(dioProvider));
});

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((
  ref,
) {
  return ProfessionalsRepository(ref.watch(professionalsDataSourceProvider));
});

/// Server-backed professionals list. The parameter is the free-text search
/// term (API_REST §10.1 `search` query param); pass '' for the full list.
final professionalsListProvider =
    FutureProvider.family<List<Professional>, String>((ref, search) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getProfessionals(search: search);
    });

final professionalDetailProvider =
    FutureProvider.family<ProfessionalDetail, String>((ref, coId) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getProfessionalInfos(coId);
    });

final professionalDisponibilitiesProvider = FutureProvider<List<dynamic>>((
  ref,
) async {
  return ref.watch(professionalsRepositoryProvider).getDisponibilities();
});

const _monthShortNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatSlotDay(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) {
    return isoDate;
  }
  return '${_monthShortNames[month - 1]} $day';
}

String? _extractTime(String? dateTime) {
  if (dateTime == null || dateTime.isEmpty) return null;
  // Backend returns "YYYY-MM-DD HH:mm:ss" (space separator), but some
  // responses use the ISO "T" separator. Extract the "HH:mm" part either way.
  var timePart = dateTime;
  final tIndex = dateTime.indexOf('T');
  final spaceIndex = dateTime.indexOf(' ');
  if (tIndex >= 0) {
    timePart = dateTime.substring(tIndex + 1);
  } else if (spaceIndex >= 0) {
    timePart = dateTime.substring(spaceIndex + 1);
  }
  final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(timePart);
  if (match == null) return null;
  return '${match.group(1)}:${match.group(2)}';
}

String _formatAppointmentDay(String? name, String? dateTime) {
  final dateLabel = _formatSlotDay(
    dateTime == null || dateTime.isEmpty ? '' : dateTime.substring(0, 10),
  );
  final time = _extractTime(dateTime);
  final when = [
    if (dateLabel.isNotEmpty &&
        !dateLabel.startsWith('0000') &&
        dateLabel != 'Jan 00')
      dateLabel,
    ?time,
  ].join(' • ');
  if (name != null && name.trim().isNotEmpty) {
    return '$name • $when';
  }
  return when.isEmpty ? 'Available' : when;
}

/// Expands raw availability rules (`disponibilities`) into concrete,
/// future bookable slots.
///
/// The backend's `nextdisponibilities` (pre-computed slots) is only returned
/// reliably on the professional's own availability endpoint. The customer-facing
/// detail endpoint returns raw rules instead. Each rule:
///   - `di_include`: true = available, false = blocked
///   - `di_what`: "days" (recurring weekday via di_days) or "date" (single day)
///   - `di_days`: ISO weekdays 1=Mon..7=Sun
///   - `di_date_from` / `di_date_to`: inclusive range (YYYY-MM-DD)
///   - `di_hour_from` / `di_hour_to`: inclusive range (HH:mm)
List<Map<String, dynamic>> _slotsFromDisponibilityRules(List<dynamic> rules) {
  final rows = <Map<String, dynamic>>[];
  if (rules.isEmpty) return rows;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  int parseHour(String time) {
    final parts = time.split(':');
    return int.tryParse(parts.isEmpty ? '' : parts[0]) ?? 0;
  }

  int parseMinute(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  DateTime? parseDate(dynamic value) {
    final text = value?.toString() ?? '';
    final parts = text.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  for (final rule in rules) {
    if (rule is! Map<String, dynamic>) continue;
    if (rule['di_include'] != true) continue;

    final what = rule['di_what']?.toString() ?? 'days';
    final daysSet = <int>{
      if (rule['di_days'] is List)
        for (final d in rule['di_days'])
          if (d is int) d,
    };

    final from = parseDate(rule['di_date_from']);
    final to = parseDate(rule['di_date_to']);
    if (from == null || to == null) continue;

    final hourFrom = parseHour(rule['di_hour_from']?.toString() ?? '00:00');
    final minuteFrom = parseMinute(rule['di_hour_from']?.toString() ?? '00:00');
    final hourTo = parseHour(rule['di_hour_to']?.toString() ?? '23:59');
    final minuteTo = parseMinute(rule['di_hour_to']?.toString() ?? '23:59');

    final rangeStart = from.isBefore(today) ? today : from;
    final rangeEnd = to;

    for (
      var day = rangeStart;
      !day.isAfter(rangeEnd);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final weekday = day.weekday; // 1=Mon..7=Sun (same as di_days)
      final isRecurring = what == 'days' || what == 'dates';
      final matches = isRecurring
          ? daysSet.contains(weekday)
          : what == 'date' && day == rangeStart;
      if (!matches) continue;

      final times = <String>[];
      var hour = hourFrom;
      var minute = minuteFrom;
      while (
        hour < hourTo || (hour == hourTo && minute <= minuteTo)
      ) {
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(time);
        minute += 60;
        while (minute >= 60) {
          minute -= 60;
          hour += 1;
        }
      }
      if (times.isEmpty) continue;

      final iso = day.toIso8601String().substring(0, 10);
      rows.add({
        'key': 'slot_$iso',
        'day': _formatSlotDay(iso),
        'slots': times,
        'ap_id': null,
      });
    }
  }

  rows.sort((a, b) {
    final aDate = a['day']?.toString() ?? '';
    final bDate = b['day']?.toString() ?? '';
    return aDate.compareTo(bDate);
  });

  return rows;
}

final professionalBookingSlotsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  coId,
) async {
  final payload = await ref
      .watch(professionalsRepositoryProvider)
      .getProfessionalBookingSlots(coId);

  final rows = <Map<String, dynamic>>[];

  final next = payload['nextdisponibilities'];
  if (next is List) {
    for (final entry in next) {
      if (entry is! Map<String, dynamic>) continue;
      final date = entry['date']?.toString() ?? '';
      final hours = entry['hours'];
      final times = <String>[];
      if (hours is List) {
        for (final hour in hours) {
          if (hour is List && hour.isNotEmpty) {
            final time = hour.first.toString();
            if (time.isNotEmpty) times.add(time);
          } else if (hour is String && hour.trim().isNotEmpty) {
            times.add(hour.trim());
          }
        }
      }
      if (date.isEmpty || times.isEmpty) continue;
      rows.add({
        'key': 'slot_$date',
        'day': _formatSlotDay(date),
        'slots': times,
        'ap_id': null,
      });
    }
  }

  // The customer-facing detail endpoint often returns raw availability rules
  // (`disponibilities`) instead of computed slots (`nextdisponibilities`).
  // Fall back to expanding the rules into concrete future slots.
  if (rows.isEmpty) {
    final rawRules = payload['disponibilities'];
    if (rawRules is List) {
      rows.addAll(_slotsFromDisponibilityRules(rawRules));
    }
  }

  final appointments = payload['appointments'];
  if (appointments is List) {
    for (final appt in appointments) {
      if (appt is! Map<String, dynamic>) continue;
      final apId = appt['ap_id']?.toString() ?? '';
      if (apId.isEmpty) continue;
      final name = appt['ap_name']?.toString() ?? '';
      final date = appt['ap_date']?.toString() ?? '';
      final time = _extractTime(date);
      final price = appt['ap_price'] is num
          ? (appt['ap_price'] as num).toDouble()
          : (num.tryParse(appt['ap_price']?.toString() ?? '') ?? 0).toDouble();
      rows.add({
        'key': 'ap_$apId',
        'day': _formatAppointmentDay(name, date),
        'slots': time != null ? <String>[time] : <String>[],
        'ap_id': apId,
        'ap_price': price,
      });
    }
  }

  return rows;
});

final professionalDisponibilitiesPayloadProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getDisponibilitiesPayload();
    });
