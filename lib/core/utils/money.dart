import 'package:intl/intl.dart';

/// A euro amount written the way the selected language writes it:
/// `1,50 €` in French and Spanish, `€1.50` in English.
///
/// Follows [Intl.defaultLocale], which `main.dart` keeps on the language
/// chosen in-app.
String formatEuros(num amount) => NumberFormat.currency(
  locale: Intl.defaultLocale,
  symbol: '€',
  decimalDigits: 2,
).format(amount);

/// An amount the server sent as integer cents (`topay`, `balance`,
/// `requiredAmount`…), in the app language.
String formatCents(int cents) => formatEuros(cents / 100);

/// One of the server's pre-formatted `…f` strings (`topayf`, `pricef`…),
/// rewritten in the app language.
///
/// The server's `formatPrice` is hardcoded to French (Amaury, 2026-09-21), so
/// these strings are only usable as-is in French. Prefer [formatCents] when
/// raw cents exist; use this only when the API sends nothing but the string.
String localizeServerAmount(String formatted) {
  final text = formatted.trim();
  if (text.isEmpty || (Intl.defaultLocale ?? 'fr').startsWith('fr')) {
    return text;
  }
  // French format: space (or narrow no-break space) thousands, comma decimals.
  final numeric = text
      .replaceAll(RegExp(r'[^0-9,.\-]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  final value = double.tryParse(numeric);
  return value == null ? text : formatEuros(value);
}

/// The decimal separator of the selected language: `,` in French and Spanish,
/// `.` in English.
String decimalSeparator() =>
    NumberFormat.decimalPatternDigits(
      locale: Intl.defaultLocale,
      decimalDigits: 2,
    ).symbols.DECIMAL_SEP;

/// A plain amount for an editable price field — no currency symbol, but the
/// separator the language uses, so a Spanish professional is not shown `2.50`
/// while every price elsewhere in the app reads `2,50 €`.
///
/// Parsing accepts either separator, so an edited value still round-trips.
String formatAmountForInput(num amount) =>
    amount.toStringAsFixed(2).replaceAll('.', decimalSeparator());
