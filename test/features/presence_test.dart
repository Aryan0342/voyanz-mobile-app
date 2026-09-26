import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/providers/presence_provider.dart';

// Observed on voyanz.com (2026-09-26): co_online is 1 = Available,
// 2 = In session, 0 = Not available, and the site blocks the toggle while
// the professional is in a session.
void main() {
  group('Presence.fromCode', () {
    test('maps the three backend values', () {
      expect(Presence.fromCode(1), Presence.online);
      expect(Presence.fromCode(2), Presence.inSession);
      expect(Presence.fromCode(0), Presence.offline);
    });

    test('an unknown or missing value is treated as offline', () {
      expect(Presence.fromCode(null), Presence.offline);
      expect(Presence.fromCode(7), Presence.offline);
    });
  });

  group('server-owned state', () {
    test('only the in-session state locks the switch', () {
      expect(Presence.inSession.isLockedByServer, isTrue);
      expect(Presence.online.isLockedByServer, isFalse);
      expect(Presence.offline.isLockedByServer, isFalse);
    });
  });
}
