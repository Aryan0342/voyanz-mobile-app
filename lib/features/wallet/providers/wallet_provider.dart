import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/wallet/data/wallet_data_source.dart';
import 'package:voyanz/features/wallet/data/wallet_repository.dart';
import 'package:voyanz/features/wallet/models/history_item.dart';
import 'package:voyanz/features/wallet/models/payment_intent_response.dart';
import 'package:voyanz/features/wallet/models/payment_status.dart';
import 'package:voyanz/features/wallet/models/topup_pack.dart';

final walletDataSourceProvider = Provider<WalletDataSource>((ref) {
  return WalletDataSource(ref.watch(dioProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(walletDataSourceProvider));
});

final topUpPacksProvider = FutureProvider<List<TopUpPack>>((ref) async {
  return ref.watch(walletRepositoryProvider).getPacks();
});

final walletHistoryProvider = FutureProvider<List<HistoryItem>>((ref) async {
  return ref.watch(walletRepositoryProvider).getHistory();
});

final selectedPackProvider = StateProvider<TopUpPack?>((ref) => null);

final promoCodeProvider = StateProvider<String?>((ref) => null);

final paymentIntentProvider =
    FutureProvider.autoDispose.family<PaymentIntentResponse, ({String item, String? code})>(
  (ref, params) async {
    return ref.watch(walletRepositoryProvider).createPaymentIntent(
      item: params.item,
      code: params.code,
    );
  },
);

final paymentStatusProvider =
    FutureProvider.autoDispose.family<PaymentStatusResponse, String>(
  (ref, pi) async {
    return ref.watch(walletRepositoryProvider).confirmPayment(pi);
  },
);
