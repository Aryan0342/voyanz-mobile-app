import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/account/data/account_repository.dart';

// Contract P4: a professional who changes their mobile number must verify it
// by SMS again, and the server reports that only in the update response. An
// unverified mobile keeps the profile out of the catalogue (contract P1), so
// missing the flag would silently hide a professional.
void main() {
  group('mobileReverificationRequired', () {
    test('reads the flag at the root of the response', () {
      expect(
        mobileReverificationRequired(const {
          'mobile_reverification_required': true,
        }),
        isTrue,
      );
    });

    test('reads the flag inside data', () {
      expect(
        mobileReverificationRequired(const {
          'data': {'co_id': 139, 'mobile_reverification_required': true},
        }),
        isTrue,
      );
    });

    test('accepts the truthy spellings a PHP backend may send', () {
      for (final value in [true, 1, '1', 'true']) {
        expect(
          mobileReverificationRequired({'mobile_reverification_required': value}),
          isTrue,
          reason: 'value $value',
        );
      }
    });

    test('a customer response without the flag does not ask for anything', () {
      expect(
        mobileReverificationRequired(const {
          'data': {'co_id': 42, 'co_mobile1': '+33612345678'},
          'err': null,
        }),
        isFalse,
      );
    });

    test('an explicit false is not a request', () {
      expect(
        mobileReverificationRequired(const {
          'mobile_reverification_required': false,
        }),
        isFalse,
      );
      expect(
        mobileReverificationRequired(const {
          'data': {'mobile_reverification_required': 0},
        }),
        isFalse,
      );
    });

    test('an empty response is safe', () {
      expect(mobileReverificationRequired(const {}), isFalse);
      expect(mobileReverificationRequired(const {'data': null}), isFalse);
    });
  });
}
