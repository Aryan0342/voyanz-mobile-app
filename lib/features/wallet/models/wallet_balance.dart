import 'package:voyanz/core/utils/money.dart';

class WalletBalance {
  final int balance; // cents
  final String balanceFormatted;
  final String currency;

  const WalletBalance({
    required this.balance,
    required this.balanceFormatted,
    required this.currency,
  });

  double get balanceInEuros => balance / 100;

  bool get isNegative => balance < 0;

  // From the raw cents: `balanceFormatted` is always French-formatted.
  String get display {
    final sign = isNegative ? '-' : '';
    return '$sign${formatEuros(balanceInEuros.abs())}';
  }

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: _parseCents(json['balance']),
      balanceFormatted: json['balanceFormatted']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'EUR',
    );
  }

  static int _parseCents(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 0;

    final parsedInt = int.tryParse(text);
    if (parsedInt != null) return parsedInt;

    final normalized = text.replaceAll(',', '.');
    final parsedDouble = double.tryParse(normalized);
    if (parsedDouble == null) return 0;

    return (parsedDouble * 100).round();
  }
}
