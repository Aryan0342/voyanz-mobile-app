import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/network/api_exception.dart';

// Amaury's confirmed contract (2026-09-27):
//  * customer     -> anonymised immediately
//  * professional -> { data: { deletion_requested: true } }, then deactivated,
//                    set offline and logged out
//  * during a session -> err account_deletion_in_session / 1074
//  * a co_id that is not the signed-in user -> err forbidden, nothing deleted
void main() {
  group('ApiException carries what callers branch on', () {
    test('matches on the key', () {
      const e = ApiException(
        'Suppression impossible pendant une session.',
        key: 'account_deletion_in_session',
        code: 1074,
      );
      expect(e.matches('account_deletion_in_session'), isTrue);
      expect(e.matches('forbidden'), isFalse);
    });

    // The message is prose: it is translated and may be reworded, so the old
    // `message.contains(key)` check could never fire.
    test('matches on the code when the key is absent', () {
      const e = ApiException('Deletion not possible right now.', code: 1074);
      expect(e.matches('account_deletion_in_session', 1074), isTrue);
    });

    test('does not match a different code', () {
      const e = ApiException('Forbidden', key: 'forbidden', code: 1403);
      expect(e.matches('account_deletion_in_session', 1074), isFalse);
    });

    test('still displays as the human message', () {
      const e = ApiException('Compte introuvable.', key: 'not_found');
      expect('$e', 'Compte introuvable.');
    });

    test('a prose-only error matches nothing and is shown verbatim', () {
      const e = ApiException('Something went wrong');
      expect(e.matches('account_deletion_in_session', 1074), isFalse);
      expect('$e', 'Something went wrong');
    });
  });
}
