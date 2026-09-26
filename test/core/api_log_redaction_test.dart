import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/network/api_client.dart';

void main() {
  // The Dio log interceptor prints whole request and response bodies. The
  // login body carries the plain-text password and the response carries the
  // session tokens, so neither may ever reach the device log verbatim.
  group('request log redaction', () {
    test('masks the password in a logged login body', () {
      final line = ApiClient.redactForTesting(
        '{login: someone@example.com, password: VoyanzQA2026!}',
      );
      expect(line, contains('someone@example.com'));
      expect(line, contains('<redacted>'));
      expect(line, isNot(contains('VoyanzQA2026!')));
    });

    test('masks a quoted JSON password field', () {
      final line = ApiClient.redactForTesting(
        '{"login":"a@b.c","password":"sup3r-s3cret"}',
      );
      expect(line, isNot(contains('sup3r-s3cret')));
    });

    test('masks the confirmation field used when changing a password', () {
      final line = ApiClient.redactForTesting(
        '{co_password: newPass123, co_password2: newPass123}',
      );
      expect(line, isNot(contains('newPass123')));
    });

    test('masks the access and refresh tokens from the login response', () {
      final line = ApiClient.redactForTesting(
        '{"accesstoken":"\$2a\$10\$O8oeKHkSTSnTS","refreshtoken":"abc.def"}',
      );
      expect(line, isNot(contains('O8oeKHkSTSnTS')));
      expect(line, isNot(contains('abc.def')));
    });

    test('masks a bearer header and the session cookie', () {
      final line = ApiClient.redactForTesting(
        'Authorization: Bearer tok3nValue\ncookie: cooktoken=%242a%2410%24abc; _csrf=x',
      );
      expect(line, isNot(contains('tok3nValue')));
      expect(line, isNot(contains('%242a%2410%24abc')));
    });

    // A first cut used `replaceAll` with a `$1` backreference, which Dart
    // inserts literally: the secret was removed but the line came out as
    // `x-auth-$1<redacted>`, losing the field name. Assert the label survives,
    // not merely that the secret is gone.
    test('keeps the field name it masked', () {
      expect(
        ApiClient.redactForTesting('Authorization: Bearer tok3nValue'),
        'Authorization: Bearer <redacted>',
      );
      expect(
        ApiClient.redactForTesting('x-auth-accesstoken: tok3nValue'),
        'x-auth-accesstoken: <redacted>',
      );
      expect(
        ApiClient.redactForTesting('{login: a@b.c, password: hunter2}'),
        '{login: a@b.c, password: <redacted>}',
      );
      expect(
        ApiClient.redactForTesting('cookie: cooktoken=abc123; _csrf=keepme'),
        'cookie: cooktoken=<redacted>; _csrf=keepme',
      );
    });

    test('never emits a literal backreference', () {
      final line = ApiClient.redactForTesting(
        '{"password":"p","accesstoken":"t","refreshtoken":"r"}',
      );
      expect(line, isNot(contains(r'$1')));
    });

    test('leaves an ordinary body untouched', () {
      const body = '{"co_fullname":"Pro aryan","co_id":139}';
      expect(ApiClient.redactForTesting(body), body);
    });
  });
}
