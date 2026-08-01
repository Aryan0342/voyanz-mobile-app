import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professional_account_data_source.dart';
import 'package:voyanz/features/professionals/data/professional_account_repository.dart';

final professionalAccountDataSourceProvider =
    Provider<ProfessionalAccountDataSource>((ref) {
  return ProfessionalAccountDataSource(ref.watch(dioProvider));
});

final professionalAccountRepositoryProvider =
    Provider<ProfessionalAccountRepository>((ref) {
  return ProfessionalAccountRepository(
    ref.watch(professionalAccountDataSourceProvider),
  );
});

final professionalAccountProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(professionalAccountRepositoryProvider).getAccount();
});
