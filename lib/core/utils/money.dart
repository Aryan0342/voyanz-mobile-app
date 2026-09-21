import 'package:intl/intl.dart';

/// A euro amount written the way the selected language writes it:
/// `1,50 €` in French and Spanish, `€1.50` in English.
///
/// Follows [Intl.defaultLocale], which `main.dart` keeps on the language
/// chosen in-app. In French and Spanish this matches the server's
/// pre-formatted `…f` strings (`40,00 €`), which are French-formatted in
/// every language.
String formatEuros(num amount) => NumberFormat.currency(
  locale: Intl.defaultLocale,
  symbol: '€',
  decimalDigits: 2,
).format(amount);
