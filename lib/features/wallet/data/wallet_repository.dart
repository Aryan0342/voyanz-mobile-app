import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/wallet/data/wallet_data_source.dart';
import 'package:voyanz/features/wallet/models/balance_response.dart';
import 'package:voyanz/features/wallet/models/history_item.dart';
import 'package:voyanz/features/wallet/models/payment_intent_response.dart';
import 'package:voyanz/features/wallet/models/payment_status.dart';
import 'package:voyanz/features/wallet/models/topup_pack.dart';
import 'package:voyanz/features/wallet/models/wallet_balance.dart';

class WalletRepository {
  final WalletDataSource _ds;
  String? _htmlTextCgu;
  String? _htmlTextCgs;

  WalletRepository(this._ds);

  String? get htmlTextCgu => _htmlTextCgu;
  String? get htmlTextCgs => _htmlTextCgs;

  Future<List<TopUpPack>> getPacks() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _mockPacks;
    }
    final data = await _ds.fetchPricing();
    _htmlTextCgu = data['htmlTextCgu']?.toString();
    _htmlTextCgs = data['htmlTextCgs']?.toString();
    final packs = data['packs'];
    if (packs is List) {
      return packs
          .map((p) => TopUpPack.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PaymentIntentResponse> createPaymentIntent({
    required String item,
    String? code,
  }) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return const PaymentIntentResponse(clientSecret: 'pi_mock_secret_fake');
    }
    return _ds.createPaymentIntent(item: item, code: code);
  }

  Future<PaymentStatusResponse> confirmPayment(String pi) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const PaymentStatusResponse(status: 'succeeded');
    }
    return _ds.confirmPaymentStatus(pi);
  }

  Future<WalletBalance> getBalance() async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const WalletBalance(
        balance: 5000,
        balanceFormatted: '50,00 €',
        currency: 'EUR',
      );
    }
    return _ds.fetchBalance();
  }

  Future<BalanceResponse> checkBalance({
    required String professionalId,
    required String type,
  }) async {
    return _ds.checkBalance(professionalId: professionalId, type: type);
  }

  Future<List<HistoryItem>> getHistory({
    int skip = 0,
    int limit = 20,
    String search = '',
  }) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _mockHistory;
    }
    final data = await _ds.fetchHistory(skip: skip, limit: limit, search: search);
    final items = data['data'];
    if (items is List) {
      return items
          .map((i) => HistoryItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return {'promo': {'po_code': code, 'po_purcent': 10}};
    }
    return _ds.checkPromoCode(code);
  }
}

const _mockHistory = [
  HistoryItem(
    date: '2026-07-18',
    type: 'credit',
    label: 'Top-up Découverte',
    amount: 5000,
    amountFormatted: '50,00 €',
    inWhat: 'decouverte',
  ),
  HistoryItem(
    date: '2026-07-17',
    type: 'debit',
    label: 'Session téléphone',
    amount: -1500,
    amountFormatted: '-15,00 €',
    inWhat: 'session_se_123',
  ),
  HistoryItem(
    date: '2026-07-16',
    type: 'credit',
    label: 'Bonus première recharge',
    amount: 4000,
    amountFormatted: '40,00 €',
    inWhat: 'firstinvoice',
  ),
];

const _mockPacks = [
  TopUpPack(
    id: 'decouverte',
    name: 'Découverte',
    price: 1000,
    pricef: '10,00 €',
    topay: 1000,
    topayf: '10,00 €',
    tocomptabilize: 5000,
    tocomptabilizef: '50,00 €',
    promotion: 4000,
    promotionf: '40,00 €',
    whypromo: 'firstinvoice',
    description: 'Perfect to discover our service with a bonus credit.',
  ),
  TopUpPack(
    id: 'essai',
    name: 'Essai',
    price: 2500,
    pricef: '25,00 €',
    topay: 2500,
    topayf: '25,00 €',
    tocomptabilize: 2500,
    tocomptabilizef: '25,00 €',
    promotion: 0,
    promotionf: '0 €',
    whypromo: '',
    description: 'A trial pack to get started with no commitment.',
  ),
  TopUpPack(
    id: 'standard',
    name: 'Standard',
    price: 5000,
    pricef: '50,00 €',
    topay: 5000,
    topayf: '50,00 €',
    tocomptabilize: 5000,
    tocomptabilizef: '50,00 €',
    promotion: 0,
    promotionf: '0 €',
    whypromo: '',
    description: 'Our most popular pack for regular consultations.',
  ),
  TopUpPack(
    id: 'confort',
    name: 'Confort',
    price: 10000,
    pricef: '100,00 €',
    topay: 10000,
    topayf: '100,00 €',
    tocomptabilize: 10000,
    tocomptabilizef: '100,00 €',
    promotion: 0,
    promotionf: '0 €',
    whypromo: '',
    description: 'Extra credit for extended or multiple sessions.',
  ),
  TopUpPack(
    id: 'prenium',
    name: 'Premium',
    price: 20000,
    pricef: '200,00 €',
    topay: 20000,
    topayf: '200,00 €',
    tocomptabilize: 21000,
    tocomptabilizef: '210,00 €',
    promotion: 1000,
    promotionf: '10,00 €',
    whypromo: 'promotion',
    description: 'Best value with a bonus credit included.',
  ),
];
