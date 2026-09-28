import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/config/countries.dart';

// The server stores co_country lowercase (fra) and asks callers to compare
// case-insensitively; a few legacy rows are still uppercase.
void main() {
  test('both stored casings resolve to the same dropdown value', () {
    expect(normalizeCountryCode('fra'), 'FRA');
    expect(normalizeCountryCode('FRA'), 'FRA');
    expect(normalizeCountryCode('Fra'), 'FRA');
    expect(countryName('fra'), countryName('FRA'));
  });
  test('unknown and empty stay null rather than guessing', () {
    expect(normalizeCountryCode(''), isNull);
    expect(normalizeCountryCode('zzz'), isNull);
    expect(normalizeCountryCode(null), isNull);
  });
}
