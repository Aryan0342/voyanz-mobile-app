import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/config/countries.dart';

// Read from the website's own co_country select (2026-09-27). The API doc
// recommends alpha-2, but the site sends alpha-3 and the server stores it
// lowercased ("fra"), so alpha-3 is used and lookups ignore case.
void main() {
  group('countries', () {
    test('covers the list the website offers', () {
      expect(kCountries.length, 193);
      expect(kCountries['FRA'], 'France');
      expect(kCountries['BEL'], 'Belgium');
      expect(kCountries['CHE'], 'Switzerland');
    });

    test('every code is alpha-3', () {
      for (final code in kCountries.keys) {
        expect(code.length, 3, reason: code);
        expect(code, code.toUpperCase(), reason: code);
      }
    });

    test('matches the casing the server stores', () {
      expect(normalizeCountryCode('fra'), 'FRA');
      expect(normalizeCountryCode('FRA'), 'FRA');
      expect(normalizeCountryCode(' Fra '), 'FRA');
    });

    test('an unknown or empty code is not invented', () {
      expect(normalizeCountryCode('XX'), isNull);
      expect(normalizeCountryCode(''), isNull);
      expect(normalizeCountryCode(null), isNull);
    });

    test('an unknown code still displays rather than vanishing', () {
      expect(countryName('ZZZ'), 'ZZZ');
      expect(countryName('fra'), 'France');
      expect(countryName(null), '');
    });
  });
}
