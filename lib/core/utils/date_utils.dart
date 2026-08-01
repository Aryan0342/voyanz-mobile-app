import 'package:intl/intl.dart';

/// Date/time helpers for the Voyanz backend.
///
/// The backend stores and returns every timestamp in **Europe/Paris** local
/// time (naive datetime strings with no `Z`/offset suffix — see
/// `API_REST_MOBILE_FLUTTER_EN.md`). This module interprets those strings as
/// Paris wall-clock time and converts them to the device's own timezone so the
/// UI always shows the user's local time.

class DateUtils {
  DateUtils._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy · h:mm a');

  /// Interprets a naive backend timestamp (e.g. `"2026-03-15T14:00:00"` or
  /// `"2026-06-04 21:15:30"`) as **Europe/Paris** and returns the equivalent
  /// instant in the device's local timezone.
  ///
  /// Returns `null` when [raw] is empty or unparseable.
  static DateTime? parisToLocal(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final parsed = DateTime.parse(raw.trim().replaceFirst(' ', 'T'));
      final offsetHours = _parisUtcOffset(parsed);
      // Treat the parsed wall-clock fields as Paris time by re-building them
      // in UTC, then shift by the Paris offset to get the true UTC instant.
      final parisAsUtc = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
      final utc = parisAsUtc.subtract(Duration(hours: offsetHours));
      return utc.toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Formats a backend timestamp as a short date in the device's timezone.
  /// Falls back to the raw string when parsing fails.
  static String formatDate(String? raw) {
    final local = parisToLocal(raw);
    if (local == null) return raw?.toString() ?? '';
    return _dateFormat.format(local);
  }

  /// Formats a backend timestamp as date + time in the device's timezone.
  /// Falls back to the raw string when parsing fails.
  static String formatDateTime(String? raw) {
    final local = parisToLocal(raw);
    if (local == null) return raw?.toString() ?? '';
    return _dateTimeFormat.format(local);
  }

  /// UTC offset in hours for Paris on the given (naive, Paris wall-clock) date.
  ///
  /// Europe/Paris is UTC+1 (CET) in winter and UTC+2 (CEST) during daylight
  /// saving time — DST runs from the last Sunday of March (01:00 UTC) to the
  /// last Sunday of October (01:00 UTC).
  static int _parisUtcOffset(DateTime parisLocal) {
    final dstStart = _lastSundayOf(parisLocal.year, DateTime.march, 1);
    final dstEnd = _lastSundayOf(parisLocal.year, DateTime.october, 1);
    final isDst = parisLocal.isAfter(dstStart) &&
        parisLocal.isBefore(dstEnd);
    return isDst ? 2 : 1;
  }

  static DateTime _lastSundayOf(int year, int month, int hour) {
    final lastDay = DateTime(year, month + 1, 0, hour); // day 0 = last day of month
    final daysBack = (lastDay.weekday - DateTime.sunday) % 7;
    return DateTime(year, month, lastDay.day - daysBack, hour);
  }
}
