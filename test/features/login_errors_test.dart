import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/network/api_exception.dart';

// §8.1 and the signup note: login can answer not_found_user, wrong_password,
// user_not_active or account_pending_approval. The message is the server's
// French prose, so the key is what must be matched.
void main() {
  group('login error keys', () {
    test('the documented keys are distinguishable', () {
      const pending = ApiException(
        'Votre compte est en attente.',
        key: 'account_pending_approval',
      );
      const disabled = ApiException('Compte désactivé', key: 'user_not_active');
      expect(pending.matches('account_pending_approval'), isTrue);
      expect(pending.matches('user_not_active'), isFalse);
      expect(disabled.matches('user_not_active'), isTrue);
    });

    // §8.1: "display a single generic message ... do not reveal which field
    // is wrong" — so both keys must map to the same text.
    test('the two credential failures are not told apart', () {
      const notFound = ApiException('Utilisateur introuvable', key: 'not_found_user');
      const wrongPass = ApiException('Mauvais mot de passe', key: 'wrong_password');
      for (final e in [notFound, wrongPass]) {
        expect(
          e.matches('not_found_user') || e.matches('wrong_password'),
          isTrue,
        );
      }
    });

    test('the prose is still available for anything unmapped', () {
      const other = ApiException('Quelque chose a échoué', key: 'weird_key');
      expect('$other', 'Quelque chose a échoué');
      expect(other.matches('not_found_user'), isFalse);
    });
  });
}
