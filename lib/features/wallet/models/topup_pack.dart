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
  });

  bool get isFirstPurchaseBonus => whypromo == 'firstinvoice';

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
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
