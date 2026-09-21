import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/wallet/data/wallet_data_source.dart';
import 'package:voyanz/features/wallet/data/wallet_repository.dart';
import 'package:voyanz/features/wallet/models/history_item.dart';
import 'package:voyanz/features/wallet/models/payment_intent_response.dart';
import 'package:voyanz/features/wallet/models/payment_status.dart';
import 'package:voyanz/features/wallet/models/topup_pack.dart';
import 'package:voyanz/features/wallet/models/wallet_balance.dart';

final walletDataSourceProvider = Provider<WalletDataSource>((ref) {
  return WalletDataSource(ref.watch(dioProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(walletDataSourceProvider));
});

final topUpPacksProvider = FutureProvider<List<TopUpPack>>((ref) async {
  return ref.watch(walletRepositoryProvider).getPacks();
});

/// First-purchase gift in cents, or null when the offer must not be shown.
///
/// Eligibility and amount both come from the pricing packs
/// (`isFirstInvoice` + `firstPackGiftCents`), which the server computes per
/// customer — so a customer who has already bought a pack never sees it.
/// Professionals never see it either. Any failure hides the card rather than
/// surfacing an error on Explore.
final firstPackOfferProvider = FutureProvider<int?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null || user.isProfessional) return null;
  try {
    return firstPackGiftCents(await ref.watch(topUpPacksProvider.future));
  } catch (_) {
    return null;
  }
});

/// The advertised first-purchase gift, or null when the customer isn't
/// eligible: only packs the server flags `isFirstInvoice` count.
int? firstPackGiftCents(List<TopUpPack> packs) {
  var gift = 0;
  for (final pack in packs) {
    if (pack.isFirstInvoice && pack.firstPackGiftCents > gift) {
      gift = pack.firstPackGiftCents;
    }
  }
  return gift > 0 ? gift : null;
}

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

final walletBalanceProvider = StateProvider<double?>((ref) => null);

final walletLiveBalanceProvider =
    FutureProvider.autoDispose<WalletBalance>((ref) async {
      return ref.watch(walletRepositoryProvider).getBalance();
    });
