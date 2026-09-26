import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/professionals/data/professional_account_data_source.dart';
import 'package:voyanz/features/professionals/data/professional_account_repository.dart';
import 'package:voyanz/features/professionals/models/professional_profile.dart';

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

/// The professional's own editable profile (contract P1). Also tells the app
/// whether the CGS still need accepting and whether the account is active.
final professionalProfileProvider =
    FutureProvider<ProfessionalProfile>((ref) {
  return ref.watch(professionalAccountRepositoryProvider).getProfile();
});

final professionalAccountProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(professionalAccountRepositoryProvider).getAccount();
});
