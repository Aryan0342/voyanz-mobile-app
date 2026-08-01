import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/professionals/data/professional_account_data_source.dart';

class ProfessionalAccountRepository {
  final ProfessionalAccountDataSource _ds;

  ProfessionalAccountRepository(this._ds);

  Future<Map<String, dynamic>> getAccount() async {
    if (kUseMockBackend) {
      return {
        'stripe_status': 'pending',
        'onboarding_url':
            'https://connect.stripe.com/setup/e/acct_test_mock',
        'stripe_account_id': 'acct_test_mock',
      };
    }
    return _ds.getAccount();
  }
}
