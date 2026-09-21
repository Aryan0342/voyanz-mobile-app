class TopUpPack {
  final String id;
  final String name;
  final int price;
  final String pricef;
  final int topay;
  final String topayf;
  final int tocomptabilize;
  final String tocomptabilizef;
  final int promotion;
  final String promotionf;
  final String whypromo;
  final String? description;
  final String? code;
  final int? codepurcent;

  /// True while the customer has never bought a pack: the server then adds
  /// the first-purchase gift on top of the pack's own volume bonus.
  final bool isFirstInvoice;

  /// The first-purchase gift in cents (0 once the customer has bought a pack).
  /// Already included in [tocomptabilize]; exposed so it can be advertised.
  final int firstPackGiftCents;

  const TopUpPack({
    required this.id,
    required this.name,
    required this.price,
    required this.pricef,
    required this.topay,
    required this.topayf,
    required this.tocomptabilize,
    required this.tocomptabilizef,
    required this.promotion,
    required this.promotionf,
    required this.whypromo,
    this.description,
    this.code,
    this.codepurcent,
    this.isFirstInvoice = false,
    this.firstPackGiftCents = 0,
  });

  bool get isFirstPurchaseBonus =>
      whypromo == 'firstinvoice' || (isFirstInvoice && firstPackGiftCents > 0);

  factory TopUpPack.fromJson(Map<String, dynamic> json) {
    return TopUpPack(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseInt(json['price']),
      pricef: json['pricef']?.toString() ?? '',
      topay: _parseInt(json['topay']),
      topayf: json['topayf']?.toString() ?? '',
      tocomptabilize: _parseInt(json['tocomptabilize']),
      tocomptabilizef: json['tocomptabilizef']?.toString() ?? '',
      promotion: _parseInt(json['promotion']),
      promotionf: json['promotionf']?.toString() ?? '',
      whypromo: json['whypromo']?.toString() ?? '',
      description: json['description']?.toString(),
      code: json['code']?.toString(),
      codepurcent: _parseIntOrNull(json['codepurcent']),
      isFirstInvoice: json['isFirstInvoice'] == true,
      firstPackGiftCents: _parseInt(json['firstPackGiftCents']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }
}
