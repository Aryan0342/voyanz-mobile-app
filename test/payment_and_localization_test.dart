import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/l10n/app_translations.dart';
import 'package:voyanz/features/sessions/data/sessions_data_source.dart';
import 'package:voyanz/features/wallet/models/balance_response.dart';

void main() {
  group('insufficient balance handling', () {
    test('preserves the documented check-balance response', () {
      final response = BalanceResponse.fromJson(const {
        'success': false,
        'balance': 0,
        'requiredAmount': 500,
        'balanceFormatted': '0,00 €',
        'requiredAmountFormatted': '5,00 €',
        'error': 'INSUFFICIENT_BALANCE',
        'message': 'Votre solde est insuffisant.',
      });

      expect(response.isInsufficient, isTrue);
      expect(response.message, 'Votre solde est insuffisant.');
      expect(response.requiredAmount, 500);
    });

    test('recognizes both HTTP 402 and websocket-style error codes', () {
      expect(
        const SessionLaunchException(
          'Payment required',
          statusCode: 402,
        ).isInsufficientBalance,
        isTrue,
      );
      expect(
        const SessionLaunchException(
          'Solde insuffisant',
          errorCode: 'INSUFFICIENT_BALANCE',
        ).isInsufficientBalance,
        isTrue,
      );
    });
  });

  test('critical Explore and review labels are localized in all languages', () {
    const fr = AppTranslations('fr');
    const en = AppTranslations('en');
    const es = AppTranslations('es');

    expect(fr.allAdvisors, 'Tous les voyants');
    expect(en.allAdvisors, 'All psychics');
    expect(es.allAdvisors, 'Todos los profesionales');
    expect(fr.search, 'Rechercher');
    expect(en.search, 'Search');
    expect(es.search, 'Buscar');
    expect(es.starCount(5), contains('estrellas'));
    expect(es.loginOrEmail, 'Usuario o correo electrónico');
  });
}
