import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/professionals/providers/professional_account_provider.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

/// A professional's availability, as the backend models it in `co_online`
/// (observed on voyanz.com, 2026-09-26).
enum Presence {
  offline, // 0 — "Not available"
  online, // 1 — "Available", listed under "Available now"
  inSession; // 2 — "In session", set and cleared by the server

  static Presence fromCode(int? code) => switch (code) {
    1 => Presence.online,
    2 => Presence.inSession,
    _ => Presence.offline,
  };

  /// While in a session the server owns the status: it clears it when the
  /// session ends, so the switch must not fight it.
  bool get isLockedByServer => this == Presence.inSession;
}

/// Availability of the signed-in professional, seeded from `co_online` and
/// kept current by `disponibility_changed`.
///
/// The seed has to come from `GET /web/1.0/professional/profile`: observed on
/// 2026-09-26, neither the login response nor `GET /web/1.0/user/infos`
/// returns `co_online`, so reading it from the session user pinned the switch
/// to "offline" while the server had the professional available — the first
/// tap then took them offline instead of online. The session user stays as a
/// fallback in case the field is added there later.
final professionalPresenceProvider = StateProvider<Presence>((ref) {
  final fromProfile = ref.watch(professionalProfileProvider).valueOrNull?.online;
  if (fromProfile != null) return Presence.fromCode(fromProfile);
  return Presence.fromCode(ref.watch(authStateProvider).valueOrNull?.online);
});

/// The server's reason for refusing to put a professional online — today only
/// `stripe_required_for_disponibility` (WEBSOCKET §6). Cleared once shown.
final presenceErrorProvider = StateProvider<String?>((ref) => null);

/// Flips the professional between available and unavailable.
///
/// `disponibility_change` carries **no payload**: the server toggles the
/// current value, exactly as voyanz.com does. Sending a desired value would
/// be ignored and could leave the switch out of sync, so the app mirrors the
/// website and lets `disponibility_changed` confirm the result.
Future<void> toggleProfessionalPresence(WidgetRef ref) async {
  final previous = ref.read(professionalPresenceProvider);
  if (previous.isLockedByServer) return;

  ref.read(professionalPresenceProvider.notifier).state =
      previous == Presence.online ? Presence.offline : Presence.online;
  try {
    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      await ws.connect();
    }
    if (!ws.isConnected) {
      throw StateError('WebSocket is not connected');
    }
    ws.send('disponibility_change', const {});
  } catch (_) {
    ref.read(professionalPresenceProvider.notifier).state = previous;
    rethrow;
  }
}

/// Keeps presence in sync both ways while signed in:
/// * `disponibility_changed` — `{ co_id, online }` for any professional, so
///   the directory's online badges and sections are stale.
/// * `stripe_required_for_disponibility` — this professional cannot go online
///   until Stripe payouts are set up.
final presenceRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(webSocketServiceProvider);
  final myCoId = ref.watch(authStateProvider).valueOrNull?.coId;

  void onDisponibilityChanged(Map<String, dynamic> event) {
    final data = event['data'];
    final nested = data is Map<String, dynamic> ? data : const {};
    final coId = (event['co_id'] ?? nested['co_id'])?.toString();
    final raw = event['online'] ?? nested['online'];

    if (coId != null && coId == myCoId && raw != null) {
      final code = raw is int ? raw : int.tryParse(raw.toString());
      ref.read(professionalPresenceProvider.notifier).state = Presence.fromCode(
        code,
      );
    }

    // Online status drives the Explore sections and the availability labels.
    ref.invalidate(professionalsListProvider);
    ref.invalidate(favoriteProfessionalsProvider);
    ref.invalidate(professionalDetailProvider);
  }

  void onStripeRequired(Map<String, dynamic> event) {
    ref.read(professionalPresenceProvider.notifier).state = Presence.offline;
    final data = event['data'];
    final nested = data is Map<String, dynamic> ? data : const {};
    final message = (event['message'] ?? nested['message'])?.toString();
    ref.read(presenceErrorProvider.notifier).state =
        (message != null && message.trim().isNotEmpty) ? message : '';
  }

  ws.on('disponibility_changed', onDisponibilityChanged);
  ws.on('stripe_required_for_disponibility', onStripeRequired);

  ref.onDispose(() {
    ws.off('disponibility_changed', onDisponibilityChanged);
    ws.off('stripe_required_for_disponibility', onStripeRequired);
  });
});
