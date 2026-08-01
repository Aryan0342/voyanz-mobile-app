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

  String get display {
    if (balanceFormatted.isNotEmpty) return balanceFormatted;
    final sign = isNegative ? '-' : '';
    return '$sign€${balanceInEuros.abs().toStringAsFixed(2)}';
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
