class HistoryItem {
  final String date;
  final String type;
  final String label;
  final int amount;
  final String amountFormatted;
  final String inWhat;

  const HistoryItem({
    required this.date,
    required this.type,
    required this.label,
    required this.amount,
    required this.amountFormatted,
    required this.inWhat,
  });

  bool get isCredit => type == 'credit';

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      amount: _parseInt(json['amount']),
      amountFormatted: json['amountFormatted']?.toString() ?? '',
      inWhat: json['in_what']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
