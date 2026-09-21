import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/data/professionals_repository.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class FavoriteProfessionalsNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favorite_professionals';

  FavoriteProfessionalsNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey) ?? const [];
      if (stored.isEmpty) return;
      state = <String>{...stored};
    } catch (_) {}
  }

  void setFavorite(String coId, bool isFavorite) {
    final next = <String>{...state};
    if (isFavorite) {
      next.add(coId);
    } else {
      next.remove(coId);
    }
    state = next;
    _persist(next);
  }

  /// Applies the server's per-professional `isFavorite` flags from a list
  /// response. Only the professionals in that response are touched, so a
  /// search-filtered list never drops favorites it doesn't contain.
  void sync(Map<String, bool> flags) {
    final next = <String>{...state};
    flags.forEach((coId, isFavorite) {
      if (coId.trim().isEmpty) return;
      isFavorite ? next.add(coId) : next.remove(coId);
    });
    if (next.length == state.length && next.containsAll(state)) return;
    state = next;
    _persist(next);
  }

  void replaceAll(Iterable<String> coIds) {
    final next = coIds.where((id) => id.trim().isNotEmpty).toSet();
    state = next;
    _persist(next);
  }

  Future<void> _persist(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = ids.toList()..sort();
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }
}

final favoriteProfessionalIdsProvider =
    StateNotifierProvider<FavoriteProfessionalsNotifier, Set<String>>((ref) {
      return FavoriteProfessionalsNotifier();
    });

final professionalsDataSourceProvider = Provider<ProfessionalsDataSource>((
  ref,
) {
  return ProfessionalsDataSource(ref.watch(dioProvider));
});

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((
  ref,
) {
  return ProfessionalsRepository(ref.watch(professionalsDataSourceProvider));
});

/// Server-backed professionals list. The parameter is the free-text search
/// term (API_REST §10.1 `search` query param); pass '' for the full list.
final professionalsListProvider =
    FutureProvider.family<List<Professional>, String>((ref, search) async {
      final language = ref.watch(languageProvider);
      final professionals = await ref
          .watch(professionalsRepositoryProvider)
          .getProfessionals(search: search, language: language);
      // Every professional now carries an authoritative `isFavorite` flag
      // (backend fix, 2026-09): keep the card hearts in sync with it.
      ref.read(favoriteProfessionalIdsProvider.notifier).sync({
        for (final p in professionals) p.coId: p.isFavorite,
      });
      return professionals;
    });

/// Adds or removes a favorite. Favorites are WebSocket-only (API answers §3):
/// `session_selectheart` / `session_unselectheart`. The local id set is updated
/// optimistically and rolled back if the frame cannot be sent.
Future<void> toggleProfessionalFavorite(
  WidgetRef ref, {
  required String coId,
  required bool isFavorite,
}) async {
  final ids = ref.read(favoriteProfessionalIdsProvider.notifier);
  ids.setFavorite(coId, isFavorite);
  try {
    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      await ws.connect();
    }
    if (!ws.isConnected) {
      throw StateError('WebSocket is not connected');
    }
    await ws.sendWithToken(
      isFavorite ? 'session_selectheart' : 'session_unselectheart',
      {'co_id': coId},
    );
    ref.invalidate(favoriteProfessionalsProvider);
  } catch (_) {
    ids.setFavorite(coId, !isFavorite);
    rethrow;
  }
}

/// Authoritative cross-device favorites list (API answers §3).
final favoriteProfessionalsProvider = FutureProvider<List<Professional>>((
  ref,
) async {
  final language = ref.watch(languageProvider);
  final favorites = await ref
      .watch(professionalsRepositoryProvider)
      .getProfessionals(language: language, favoritesOnly: true);
  ref
      .read(favoriteProfessionalIdsProvider.notifier)
      .replaceAll(favorites.map((p) => p.coId));
  return favorites.where((p) => !p.isAssistant).toList();
});

/// AI assistants filtered from the full professionals list (co_isassistant).
final aiAssistantsProvider = FutureProvider.family<List<Professional>, String>((
  ref,
  search,
) async {
  final all = await ref.watch(professionalsListProvider(search).future);
  return all.where((p) => p.isAssistant).toList();
});

final professionalDetailProvider =
    FutureProvider.family<ProfessionalDetail, String>((ref, coId) async {
      final language = ref.watch(languageProvider);
      final detail = await ref
          .watch(professionalsRepositoryProvider)
          .getProfessionalInfos(coId, language: language);

      // The detail response is deliberately compact. The directory response
      // contains the public biography, specialties, tools, languages, image
      // identity, availability and the crucial `co_isassistant` marker.
      final directory = await ref.watch(professionalsListProvider('').future);
      for (final item in directory) {
        if (item.coId == coId) return detail.withListFallback(item);
      }
      return detail;
    });

final professionalDisponibilitiesProvider = FutureProvider<List<dynamic>>((
  ref,
) async {
  return ref.watch(professionalsRepositoryProvider).getDisponibilities();
});

final professionalDisponibilitiesPayloadProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getDisponibilitiesPayload();
    });
