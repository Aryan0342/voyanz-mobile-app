import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/appointments/data/appointments_data_source.dart';

class AppointmentsRepository {
  final AppointmentsDataSource _ds;

  AppointmentsRepository(this._ds);

  Future<Map<String, dynamic>> register(String apId) async {
    if (kUseMockBackend) {
      return {
        'success': true,
        'ap_id': apId,
        'message': 'Appointment registered (mock mode).',
      };
    }
    return _ds.register(apId: apId);
  }
}
