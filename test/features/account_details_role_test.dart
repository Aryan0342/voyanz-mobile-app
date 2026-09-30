import 'package:flutter_test/flutter_test.dart';

/// Mirrors the decision in MyAccountScreen._load: only a professional has a
/// read endpoint for the eleven extra account fields. Asking as a customer
/// returns `{"err":{"key":"not_found","code":404,"status":200}}`, so the
/// request is skipped rather than fired and swallowed.
bool shouldFetchAccountDetails({required bool isProfessional}) =>
    isProfessional;

/// The notice explaining why fields are blank is shown whenever nothing
/// could be prefilled -- either the call failed, or it was never made.
bool shouldShowPartialNotice({
  required bool isProfessional,
  required bool callFailed,
}) => !isProfessional || callFailed;

void main() {
  group('account details by role', () {
    test('a professional fetches them', () {
      expect(shouldFetchAccountDetails(isProfessional: true), isTrue);
    });

    test('a customer does not fire a request that cannot succeed', () {
      expect(shouldFetchAccountDetails(isProfessional: false), isFalse);
    });

    test('a customer is told why the fields are blank', () {
      expect(
        shouldShowPartialNotice(isProfessional: false, callFailed: false),
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
