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

  Future<void> changePassword(String coId, String password, String confirm) =>
      _ds.changePassword(coId: coId, password: password, confirmation: confirm);

  Future<void> changeEmail(String coId, String email) =>
      _ds.changeEmail(coId: coId, email: email);

  /// True when deletion was only requested (professional accounts).
  Future<bool> deleteAccount(String coId) => _ds.deleteAccount(coId: coId);

  Future<void> uploadProfileImage(String coId, String dataUri) =>
      _ds.uploadProfileImage(coId: coId, dataUri: dataUri);
}
