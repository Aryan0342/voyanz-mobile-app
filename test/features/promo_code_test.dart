import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/wallet/screens/topup_screen.dart'
    show promoPercentForTest;

void main() {
  group('promo discount', () {
    // The confirmation used to be built with an empty discount, rendering
    // "Code X applied: %" with a bare percent sign.
    test('reads the nested po_purcent the server sends', () {
      expect(
        promoPercentForTest({
          'promo': {'po_code': 'SUMMER', 'po_purcent': 10},
        }),
        '10',
      );
    });

    test('drops a trailing .0 rather than showing "10.0%"', () {
      expect(
        promoPercentForTest({
          'promo': {'po_purcent': 10.0},
        }),
        '10',
      );
    });

    test('keeps a real fraction', () {
      expect(
        promoPercentForTest({
          'promo': {'po_purcent': 12.5},
        }),
        '12.5',
      );
    });

    test('accepts the value as a string', () {
      expect(
        promoPercentForTest({
          'promo': {'po_purcent': '15'},
        }),
        '15',
      );
    });

    // Without a discount the caller falls back to a message that does not
    // promise a percentage at all.
    test('returns null when the server names no discount', () {
      expect(promoPercentForTest({'promo': <String, dynamic>{}}), isNull);
      expect(promoPercentForTest({'promo': {'po_purcent': 0}}), isNull);
      expect(promoPercentForTest(<String, dynamic>{}), isNull);
    });
  });
}
