import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';
import 'package:voyanz/features/professionals/providers/presence_provider.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';

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

  // Regression: neither POST /api/1.0/login nor GET /web/1.0/user/infos
  // returns co_online (verified against the live server on 2026-09-26), so
  // seeding the switch from the session user always said "offline". A
  // professional the server had listed as available saw an Offline switch,
  // and their first tap took them offline instead of online.
  group('the switch is seeded from the profile response', () {
    ProviderContainer containerFor(ProfessionalProfile profile) {
      final container = ProviderContainer(
        overrides: [
          professionalProfileProvider.overrideWith((ref) async => profile),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('co_online 1 seeds Available, not Offline', () async {
      final container = containerFor(const ProfessionalProfile(online: 1));
      await container.read(professionalProfileProvider.future);
      expect(container.read(professionalPresenceProvider), Presence.online);
    });

    test('co_online 2 seeds the locked in-session state', () async {
      final container = containerFor(const ProfessionalProfile(online: 2));
      await container.read(professionalProfileProvider.future);
      final presence = container.read(professionalPresenceProvider);
      expect(presence, Presence.inSession);
      expect(presence.isLockedByServer, isTrue);
    });

    test('co_online 0 seeds Offline', () async {
      final container = containerFor(const ProfessionalProfile(online: 0));
      await container.read(professionalProfileProvider.future);
      expect(container.read(professionalPresenceProvider), Presence.offline);
    });
  });

  group('ProfessionalProfile.online', () {
    test('reads co_online from the documented envelope', () {
      final profile = ProfessionalProfile.fromJson(const {
        'data': {'co_id': 139, 'co_online': 1},
      });
      expect(profile.online, 1);
    });

    test('a missing co_online stays null instead of claiming offline', () {
      final profile = ProfessionalProfile.fromJson(const {
        'data': {'co_id': 139},
      });
      expect(profile.online, isNull);
    });

    test('distinguishes an explicit 0 from a missing field', () {
      final profile = ProfessionalProfile.fromJson(const {
        'data': {'co_online': 0},
      });
      expect(profile.online, 0);
    });
  });
}
