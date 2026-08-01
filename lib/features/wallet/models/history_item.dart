import 'package:voyanz/core/utils/date_utils.dart';

class HistoryItem {
  final String date;
  final String type;
  final String subtype;
  final String label;
  final int amount;
  final String amountFormatted;
  final String inWhat;

  const HistoryItem({
    required this.date,
    required this.type,
    this.subtype = '',
    required this.label,
    required this.amount,
    required this.amountFormatted,
    required this.inWhat,
  });

  bool get isCredit =>
      type == 'credit' ||
      type == 'invoice' ||
      type == 'topup' ||
      type == 'top-up' ||
      type == 'payment';

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? '';
    final rawSubtype = json['subtype']?.toString() ?? '';
    final rawDate = json['date']?.toString() ?? '';

    return HistoryItem(
      date: DateUtils.formatDateTime(rawDate),
      type: rawType,
      subtype: rawSubtype,
      label: _firstNonEmpty([
        json['title'],
        json['label'],
        json['name'],
        _defaultTitle(rawType, rawSubtype),
      ]),
      amount: _parseAmount(json),
      amountFormatted: _firstNonEmpty([
        json['amountFormatted'],
        json['amountf'],
        json['pricef'],
        json['totalf'],
        json['topayf'],
        _formatFromCents(_parseAmount(json)),
      ]),
      inWhat: _firstNonEmpty([
        json['in_what'],
        json['inWhat'],
        json['item'],
        _inWhatFromType(rawType, json['id']),
      ]),
    );
  }

  static String _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      final text = c?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _defaultTitle(String type, String subtype) {
    final label = subtype.isNotEmpty ? subtype : type;
    if (label.isEmpty) return '';
    return label[0].toUpperCase() + label.substring(1);
  }

  static String _inWhatFromType(String type, dynamic id) {
    if (id == null) return type;
    return '$type${id is int ? '_$id' : ''}';
  }

  static int _parseAmount(Map<String, dynamic> json) {
    final direct = _parseInt(json['amount']);
    if (direct != 0) return direct;

    for (final key in ['price', 'topay', 'tocomptabilize', 'total']) {
      final parsed = _parseInt(json[key]);
      if (parsed != 0) return parsed;
    }

    final formatted = _firstNonEmpty([
      json['amountFormatted'],
      json['amountf'],
      json['pricef'],
      json['totalf'],
      json['topayf'],
    ]);
    return _centsFromFormatted(formatted);
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed ?? 0;
  }

  static int _centsFromFormatted(String formatted) {
    if (formatted.isEmpty) return 0;
    final negative = formatted.contains('-');
    final normalized = formatted
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return 0;
    final cents = (parsed.abs() * 100).round();
    return negative ? -cents : cents;
  }

  static String _formatFromCents(int cents) {
    if (cents == 0) return '';
    final sign = cents < 0 ? '-' : '';
    return '$sign€${(cents.abs() / 100).toStringAsFixed(2)}';
  }
}
