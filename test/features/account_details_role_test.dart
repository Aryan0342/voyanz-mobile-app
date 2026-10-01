import 'package:flutter_test/flutter_test.dart';

/// Each role has its own read endpoint for the extra account fields; the
/// customer's was added on 2026-10-02, so both are fetched now.
String accountDetailsPath({required bool isProfessional}) => isProfessional
    ? '/web/1.0/professional/account-details'
    : '/web/1.0/customer/account-details';

/// The notice explaining why fields are blank is shown whenever nothing
/// could be prefilled -- either the call failed, or it was never made.
bool shouldShowPartialNotice({
  required bool isProfessional,
  required bool callFailed,
}) => callFailed;

void main() {
  group('account details by role', () {
    test('each role asks its own endpoint', () {
      expect(
        accountDetailsPath(isProfessional: true),
        '/web/1.0/professional/account-details',
      );
      expect(
        accountDetailsPath(isProfessional: false),
        '/web/1.0/customer/account-details',
      );
    });

    test('a customer whose fetch works sees no notice', () {
      expect(
        shouldShowPartialNotice(isProfessional: false, callFailed: false),
        isFalse,
      );
    });

    test('a customer whose fetch failed is told', () {
      expect(
        shouldShowPartialNotice(isProfessional: false, callFailed: true),
        isTrue,
      );
    });

    test('a professional sees no notice once the fetch works', () {
      expect(
        shouldShowPartialNotice(isProfessional: true, callFailed: false),
        isFalse,
      );
    });

    test('a professional whose fetch failed is told', () {
      expect(
        shouldShowPartialNotice(isProfessional: true, callFailed: true),
        isTrue,
      );
    });
  });
}
