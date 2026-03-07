import 'package:voyanz/features/appointments/data/appointments_data_source.dart';

class AppointmentsRepository {
  final AppointmentsDataSource _ds;

  AppointmentsRepository(this._ds);

  Future<Map<String, dynamic>> register(String apId) =>
      _ds.register(apId: apId);
}
