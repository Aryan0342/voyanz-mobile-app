import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/core/utils/money.dart';

void main() {
  _priceFieldSeparator();
  setUpAll(() async => initializeDateFormatting());
  tearDown(() => Intl.defaultLocale = null);

  // The server's formatPrice is hardcoded to French (Amaury, 2026-09-21).
  group('amounts follow the app language', () {
    test('raw cents', () {
      Intl.defaultLocale = 'en';
      expect(formatCents(4000), '€40.00');
      Intl.defaultLocale = 'fr';
      expect(formatCents(4000), matches(r'^40,00\s€$'));
      Intl.defaultLocale = 'es';
      expect(formatCents(150), matches(r'^1,50\s€$'));
    });

    test('server strings are rewritten outside French', () {
      Intl.defaultLocale = 'en';
      expect(localizeServerAmount('40,00 €'), '€40.00');
      expect(localizeServerAmount('1 234,56 €'), '€1,234.56');
      expect(localizeServerAmount('-12,50 €'), '-€12.50');
    });

    test('server strings are kept verbatim in French', () {
      Intl.defaultLocale = 'fr';
      expect(localizeServerAmount('40,00 €'), '40,00 €');
    });

    test('unparseable strings are left alone', () {
      Intl.defaultLocale = 'en';
      expect(localizeServerAmount('gratuit'), 'gratuit');
      expect(localizeServerAmount(''), '');
    });
  });

  // Club Voyanz has no customer; 1-to-1 keeps one even with an ap_id.
  group('group session detection', () {
    Map<String, dynamic> started(Object? customer, Object? apId) => {
      'session': {
        'se_id': 1,
        'co_id_professional': 7,
        'co_id_customer': customer,
        'ap_id': apId,
      },
    };

    test('Club session (no customer) is a group session', () {
      expect(SessionStartedEvent.fromEvent(started(null, 73)).isGroupSession, isTrue);
    });

    test('1-to-1 appointment session is kept', () {
      expect(SessionStartedEvent.fromEvent(started(184, 73)).isGroupSession, isFalse);
    });

    test('plain 1-to-1 session is kept', () {
      expect(SessionStartedEvent.fromEvent(started(184, null)).isGroupSession, isFalse);
    });
  });
}

// A price field is editable, so it carries no currency symbol -- but showing
// `2.50` to a Spanish professional contradicted every other price in the app.
void _priceFieldSeparator() {
  group('formatAmountForInput', () {
    tearDown(() => Intl.defaultLocale = 'fr');

    test('uses a comma in French and Spanish', () {
      Intl.defaultLocale = 'fr';
      expect(formatAmountForInput(2.5), '2,50');
      Intl.defaultLocale = 'es';
      expect(formatAmountForInput(2.5), '2,50');
    });

    test('uses a dot in English', () {
      Intl.defaultLocale = 'en';
      expect(formatAmountForInput(2.5), '2.50');
    });

    test('always keeps two decimals', () {
      Intl.defaultLocale = 'en';
      expect(formatAmountForInput(3), '3.00');
      Intl.defaultLocale = 'es';
      expect(formatAmountForInput(3), '3,00');
    });

    test('round-trips through the editor parser in every language', () {
      for (final locale in ['fr', 'en', 'es']) {
        Intl.defaultLocale = locale;
        final shown = formatAmountForInput(2.5);
        // Mirrors _priceOf in the edit screen.
        final parsed = double.tryParse(shown.replaceAll(',', '.'));
        expect(parsed, 2.5, reason: 'locale $locale showed "$shown"');
      }
    });
  });
}
