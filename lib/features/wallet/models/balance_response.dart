class BalanceResponse {
  final bool success;
  final int balance;
  final int requiredAmount;
  final String balanceFormatted;
  final String requiredAmountFormatted;
  final String? error;
  final String message;

  const BalanceResponse({
    required this.success,
    required this.balance,
    required this.requiredAmount,
    required this.balanceFormatted,
    required this.requiredAmountFormatted,
    this.error,
    required this.message,
  });

  bool get isInsufficient => error == 'INSUFFICIENT_BALANCE';

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      success: json['success'] == true,
      balance: _parseInt(json['balance']),
      requiredAmount: _parseInt(json['requiredAmount']),
      balanceFormatted: json['balanceFormatted']?.toString() ?? '',
      requiredAmountFormatted: json['requiredAmountFormatted']?.toString() ?? '',
      error: json['error']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
