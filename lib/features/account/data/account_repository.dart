import 'package:voyanz/features/account/data/account_data_source.dart';

class AccountRepository {
  final AccountDataSource _ds;

  AccountRepository(this._ds);

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> body) =>
      _ds.createAccount(body: body);

  Future<Map<String, dynamic>> updateAccount(
    String coId,
    Map<String, dynamic> body,
  ) => _ds.updateAccount(coId: coId, body: body);

  Future<Map<String, dynamic>> updateProDescription(
    String coId,
    Map<String, dynamic> body,
  ) => _ds.updateProDescription(coId: coId, body: body);
}
