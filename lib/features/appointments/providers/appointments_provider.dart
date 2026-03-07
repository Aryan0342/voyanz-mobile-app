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
