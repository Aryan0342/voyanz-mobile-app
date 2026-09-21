import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/chat/providers/chat_messages_notifier.dart';
import 'package:voyanz/features/chat/providers/chat_provider.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/sessions/providers/sessions_provider.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

/// Drops every piece of state that belongs to the signed-in user.
///
/// Riverpod keeps non-autoDispose providers alive for the whole app session,
/// so without this a second account signing in on the same device would be
/// served the previous account's wallet, history, reviews, chats and
/// favorites until each screen happened to refetch.
///
/// Call it whenever the signed-in user changes (logout, forced logout on an
/// expired token, or a different account signing in).
void resetUserScopedState(WidgetRef ref) {
  // Favorites are also persisted to disk, so empty them rather than just
  // invalidating (a fresh notifier would reload the old user's set).
  ref.read(favoriteProfessionalIdsProvider.notifier).replaceAll(const []);

  // Directory: each professional carries a per-user `isFavorite` flag.
  ref.invalidate(professionalsListProvider);
  ref.invalidate(favoriteProfessionalsProvider);
  ref.invalidate(aiAssistantsProvider);
  ref.invalidate(professionalDetailProvider);

  // Professional-side data.
  ref.invalidate(professionalDisponibilitiesProvider);
  ref.invalidate(professionalDisponibilitiesPayloadProvider);
  ref.invalidate(professionalAccountProvider);

  // History and reviews.
  ref.invalidate(customerHistoryProvider);
  ref.invalidate(professionalHistoryProvider);
  ref.invalidate(customerReviewsProvider);
  ref.invalidate(professionalReviewsProvider);
  ref.invalidate(customerPricingProvider);
  ref.invalidate(reviewEligibilityProvider);

  // Wallet, packs and the first-purchase offer (eligibility is per customer).
  ref.invalidate(topUpPacksProvider);
  ref.invalidate(firstPackOfferProvider);
  ref.invalidate(walletHistoryProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletLiveBalanceProvider);
  ref.invalidate(selectedPackProvider);
  ref.invalidate(promoCodeProvider);

  // Chat.
  ref.invalidate(chatGroupsProvider);
  ref.invalidate(chatMessagesProvider);
  ref.invalidate(chatMessagesPageProvider);
  ref.invalidate(chatMessagesNotifierProvider);
  ref.invalidate(chatUnreadCountsProvider);

  // Sessions.
  ref.invalidate(sessionStatusProvider);
  ref.invalidate(videoTokenProvider);
}
