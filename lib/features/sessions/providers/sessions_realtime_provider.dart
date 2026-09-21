import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';
import 'package:voyanz/features/wallet/providers/wallet_provider.dart';

/// Keeps history and wallet fresh when a session starts or ends.
///
/// The server pushes `sessions_updated` whenever the user's sessions change
/// (WEBSOCKET §6). Sessions are billed when they end (PAYMENT Q12, Q23), so
/// that is exactly when history, review eligibility and balance go stale.
/// Without this the History tab kept showing the pre-session list until the
/// user pulled to refresh.
final sessionsRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(webSocketServiceProvider);

  void handler(Map<String, dynamic> _) {
    ref.invalidate(customerHistoryProvider);
    ref.invalidate(professionalHistoryProvider);
    ref.invalidate(walletHistoryProvider);
    ref.invalidate(walletLiveBalanceProvider);
  }

  ws.on('sessions_updated', handler);
  ref.onDispose(() => ws.off('sessions_updated', handler));
});
