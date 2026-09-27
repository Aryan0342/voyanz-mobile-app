import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/reviews/data/review_sanitizer.dart';

// GET /web/1.0/professional/reviews embeds the reviewer's entire account record
// in every received review. Captured from the live server, 2026-09-27 — these
// are the field names it really sent, values replaced.
const _liveReview = {
  'rv_id': 9,
  'ag_id': 'voyanz',
  'co_id_customer': 184,
  'co_id_professional': 139,
  'rv_ispro': false,
  'rv_note': 5,
  'rv_text': 'nice experience',
  'rv_validated': true,
  'createdAt': '2026-08-14 23:14:58',
  'updatedAt': '2026-08-14 23:14:58',
  'customer': {
    'co_id': 184,
    'co_fullname': 'Shahzeb QA',
    'co_firstname': 'Shahzeb',
    'co_name': 'QA',
    'co_password': r'$2a$10$ZTRk6bzAjYK6yjhBuuppbu',
    'co_accesstoken': r'$2a$10$4mC9DJ.JZy3LdYVAAW7m1e',
    'co_refreshtoken': r'$2a$10$IlYIPIuy8wHHVT06Kp1h7u',
    'co_stripe_customer_id': 'cus_V4rx4bcclsX5JV',
    'co_stripe_account': {'id': 'cus_V4rx4bcclsX5JV', 'livemode': true},
    'co_birthday': '1951-12-19',
    'co_mobile1': '+923485143576',
    'co_iban': '',
    'co_email1': 'voyanz.qa.client@yopmail.com',
    'co_address1': '',
    'co_city': '',
  },
};

void main() {
  group('sanitizeReview', () {
    final clean = sanitizeReview(_liveReview);
    final customer = clean['customer'] as Map<String, dynamic>;

    test('keeps what the card shows', () {
      expect(clean['rv_note'], 5);
      expect(clean['rv_text'], 'nice experience');
      expect(clean['rv_ispro'], false);
      expect(clean['createdAt'], '2026-08-14 23:14:58');
      expect(customer['co_fullname'], 'Shahzeb QA');
      expect(customer['co_id'], 184);
    });

    test('drops the credentials', () {
      for (final key in [
        'co_password',
        'co_accesstoken',
        'co_refreshtoken',
      ]) {
        expect(customer.containsKey(key), isFalse, reason: key);
      }
    });

    test('drops the payment identifiers', () {
      expect(customer.containsKey('co_stripe_customer_id'), isFalse);
      expect(customer.containsKey('co_stripe_account'), isFalse);
    });

    test('drops the personal data the card never shows', () {
      for (final key in [
        'co_birthday',
        'co_mobile1',
        'co_iban',
        'co_email1',
        'co_address1',
        'co_city',
      ]) {
        expect(customer.containsKey(key), isFalse, reason: key);
      }
    });

    test('nothing sensitive survives anywhere in the result', () {
      final dumped = clean.toString();
      for (final secret in [
        r'$2a$10$ZTRk6bzAjYK6yjhBuuppbu',
        r'$2a$10$4mC9DJ.JZy3LdYVAAW7m1e',
        'cus_V4rx4bcclsX5JV',
        '1951-12-19',
        '+923485143576',
      ]) {
        expect(dumped, isNot(contains(secret)), reason: secret);
      }
    });

    // A whitelist means a field the backend adds later is excluded by default.
    test('an unknown new field is not carried through', () {
      final clean = sanitizeReview({
        'rv_id': 1,
        'co_secret_new_field': 'leak',
        'customer': {'co_fullname': 'X', 'co_new_secret': 'leak'},
      });
      expect(clean.containsKey('co_secret_new_field'), isFalse);
      expect(
        (clean['customer'] as Map).containsKey('co_new_secret'),
        isFalse,
      );
    });
  });

  group('sanitizeReviews', () {
    test('cleans every row and drops malformed ones', () {
      final list = sanitizeReviews([_liveReview, 'nonsense', 42, null]);
      expect(list, hasLength(1));
      expect(
        (list.single as Map)['customer'],
        isNot(contains('co_password')),
      );
    });

    test('an empty list stays empty', () {
      expect(sanitizeReviews(const []), isEmpty);
    });
  });
}
