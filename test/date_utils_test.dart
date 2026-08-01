import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/utils/date_utils.dart';

void main() {
  group('DateUtils.parisToLocal', () {
    test('interprets Paris summer time (UTC+2) correctly', () {
      // 2026-07-15 14:00 Paris (CEST = UTC+2) = 12:00 UTC.
      final local = DateUtils.parisToLocal('2026-07-15T14:00:00');
      expect(local, isNotNull);
      expect(local!.isUtc, isFalse);
      expect(local.toUtc().hour, 12);
    });

    test('interprets Paris winter time (UTC+1) correctly', () {
      // 2026-01-15 14:00 Paris (CET = UTC+1) = 13:00 UTC.
      final local = DateUtils.parisToLocal('2026-01-15T14:00:00');
      expect(local, isNotNull);
      expect(local!.toUtc().hour, 13);
    });

    test('handles space-separated MySQL datetime', () {
      final local = DateUtils.parisToLocal('2026-06-04 21:15:30');
      expect(local, isNotNull);
    });

    test('returns null for empty or invalid input', () {
      expect(DateUtils.parisToLocal(''), isNull);
      expect(DateUtils.parisToLocal(null), isNull);
      expect(DateUtils.parisToLocal('not a date'), isNull);
    });
  });

  group('DateUtils.formatDateTime', () {
    test('formats a valid timestamp', () {
      final result = DateUtils.formatDateTime('2026-07-15T14:00:00');
      expect(result, isNotEmpty);
      expect(result, contains('2026'));
      expect(result, contains(RegExp(r'(AM|PM)')));
    });

    test('falls back to raw string when unparseable', () {
      expect(DateUtils.formatDateTime('garbage'), 'garbage');
    });
  });
}
