import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/data/professionals_repository.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

class FavoriteProfessionalsNotifier extends StateNotifier<Set<String>> {
  FavoriteProfessionalsNotifier() : super(<String>{});

  void setFavorite(String coId, bool isFavorite) {
    final next = <String>{...state};
    if (isFavorite) {
      next.add(coId);
    } else {
      next.remove(coId);
    }
    state = next;
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

final professionalsListProvider = FutureProvider<List<Professional>>((
  ref,
) async {
  return ref.watch(professionalsRepositoryProvider).getProfessionals();
});

final professionalDetailProvider =
    FutureProvider.family<ProfessionalDetail, String>((ref, coId) async {
      return ref
          .watch(professionalsRepositoryProvider)
          .getProfessionalInfos(coId);
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
