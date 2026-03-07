import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/account/data/account_data_source.dart';
import 'package:voyanz/features/account/data/account_repository.dart';

final accountDataSourceProvider = Provider<AccountDataSource>((ref) {
  return AccountDataSource(ref.watch(dioProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(accountDataSourceProvider));
});
