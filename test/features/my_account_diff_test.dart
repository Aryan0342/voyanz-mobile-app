import 'package:flutter_test/flutter_test.dart';

/// Mirrors the diff the account screen builds before saving.
///
/// `GET /web/1.0/user/infos` returns only 13 fields and none of co_sex,
/// co_birthday, co_country, co_mobile1, co_legal_structure_type, co_siret,
/// co_iban, co_address1/2, co_zip or co_city (verified against the live
/// server, 2026-09-28). Sending the whole form would therefore replace real
/// values with the blanks the screen could not prefill. The endpoint merges,
/// so only what changed is sent.
Map<String, dynamic> buildBody(
  Map<String, String> loaded,
  Map<String, String> current,
) {
  final body = <String, dynamic>{};
  current.forEach((key, value) {
    if (value != (loaded[key] ?? '')) body[key] = value;
  });
  return body;
}

void main() {
  group('account update body', () {
    test('a field the server never returned is not sent when untouched', () {
      // The screen could not prefill the address, so it must not clear it.
      final body = buildBody(
        {'co_firstname': 'Pro', 'co_name': 'aryan'},
        {'co_firstname': 'Pro', 'co_name': 'aryan', 'co_address1': ''},
      );
      expect(body, isEmpty);
    });

    test('sends only what changed', () {
      final body = buildBody(
        {'co_firstname': 'Pro', 'co_name': 'aryan', 'co_city': ''},
        {'co_firstname': 'Pro', 'co_name': 'Aryan', 'co_city': ''},
      );
      expect(body, {'co_name': 'Aryan'});
    });

    test('a field the professional fills in is sent', () {
      final body = buildBody(
        {'co_city': ''},
        {'co_city': 'Paris'},
      );
      expect(body, {'co_city': 'Paris'});
    });

    test('deliberately clearing a loaded field is still sent', () {
      final body = buildBody(
        {'co_society': 'Voyanz SARL'},
        {'co_society': ''},
      );
      expect(body, {'co_society': ''});
    });

    test('an unknown gender is not written as a default', () {
      // The chips start unselected when the server did not say; leaving them
      // alone must not claim the account is "na".
      final body = buildBody({'co_sex': ''}, {'co_sex': ''});
      expect(body.containsKey('co_sex'), isFalse);
    });

    test('a chosen gender is written', () {
      expect(buildBody({'co_sex': ''}, {'co_sex': 'female'}), {
        'co_sex': 'female',
      });
    });

    test('nothing changed means no request at all', () {
      final loaded = {
        'co_firstname': 'Pro',
        'co_name': 'aryan',
        'co_society': '',
      };
      expect(buildBody(loaded, Map<String, String>.from(loaded)), isEmpty);
    });
  });
}
