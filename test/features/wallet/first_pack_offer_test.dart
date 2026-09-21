import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/features/wallet/models/topup_pack.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

/// Shape of one pack from GET /web/1.0/customer/pricing (production).
Map<String, dynamic> _pack({
  required String id,
  required int price,
  required bool isFirstInvoice,
  required int giftCents,
}) => {
  'id': id,
  'name': id,
  'price': price,
  'pricef': '',
  'topay': price,
  'topayf': '',
  'tocomptabilize': price + giftCents,
  'tocomptabilizef': '',
  'promotion': 0,
  'promotionf': '',
  'whypromo': '',
  'isFirstInvoice': isFirstInvoice,
  'firstPackGiftCents': giftCents,
};

void main() {
  group('first-pack offer', () {
    test('parses isFirstInvoice and firstPackGiftCents', () {
      final pack = TopUpPack.fromJson(
        _pack(id: 'package1', price: 4000, isFirstInvoice: true, giftCents: 2000),
      );
      expect(pack.isFirstInvoice, isTrue);
      expect(pack.firstPackGiftCents, 2000);
      expect(pack.isFirstPurchaseBonus, isTrue);
    });

    test('an eligible first-time customer gets the gift amount', () {
      final packs = [
        _pack(id: 'package1', price: 4000, isFirstInvoice: true, giftCents: 2000),
        _pack(id: 'package4', price: 40000, isFirstInvoice: true, giftCents: 2000),
      ].map(TopUpPack.fromJson).toList();
      expect(firstPackGiftCents(packs), 2000);
    });

    test('a customer who already bought a pack sees no offer', () {
      // This is what the QA client account returns in production.
      final packs = [
        _pack(id: 'package1', price: 4000, isFirstInvoice: false, giftCents: 0),
        _pack(id: 'package2', price: 8000, isFirstInvoice: false, giftCents: 0),
      ].map(TopUpPack.fromJson).toList();
      expect(firstPackGiftCents(packs), isNull);
    });

    test('a gift amount without the first-invoice flag is ignored', () {
      final packs = [
        _pack(id: 'package1', price: 4000, isFirstInvoice: false, giftCents: 2000),
      ].map(TopUpPack.fromJson).toList();
      expect(firstPackGiftCents(packs), isNull);
    });

    test('missing fields (older backend) mean no offer', () {
      final pack = TopUpPack.fromJson({'id': 'package1', 'price': 4000});
      expect(pack.isFirstInvoice, isFalse);
      expect(pack.firstPackGiftCents, 0);
      expect(firstPackGiftCents([pack]), isNull);
    });
  });
}
