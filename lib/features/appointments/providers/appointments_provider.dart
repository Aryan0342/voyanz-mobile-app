import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/appointments/data/appointments_data_source.dart';
import 'package:voyanz/features/appointments/data/appointments_repository.dart';

final appointmentsDataSourceProvider = Provider<AppointmentsDataSource>((ref) {
  return AppointmentsDataSource(ref.watch(dioProvider));
});

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(appointmentsDataSourceProvider));
});

final publicVideoSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final now = DateTime.now();
  final end = now.add(const Duration(days: 30));
  return ref
      .watch(appointmentsRepositoryProvider)
      .getPublicVideoSessions(from: now, to: end);
});
