import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professionals_data_source.dart';
import 'package:voyanz/features/professionals/data/professionals_repository.dart';
import 'package:voyanz/features/professionals/models/professional.dart';

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
