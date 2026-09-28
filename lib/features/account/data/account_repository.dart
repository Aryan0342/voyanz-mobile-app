import 'package:voyanz/features/account/data/account_data_source.dart';

class AccountRepository {
  final AccountDataSource _ds;

  AccountRepository(this._ds);

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> body) =>
      _ds.createAccount(body: body);

  Future<Map<String, dynamic>> getUserInfos() => _ds.getUserInfos();

  Future<Map<String, dynamic>> getAccountDetails() => _ds.getAccountDetails();

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

/// True when the server asks for the mobile number to be verified again after
/// a change (contract P4: professionals only).
///
/// Unverified mobile keeps a professional out of the catalogue, so this cannot
/// be ignored: the response is the only place it is reported.
bool mobileReverificationRequired(Map<String, dynamic> response) {
  bool flagged(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';

  if (flagged(response['mobile_reverification_required'])) return true;
  final data = response['data'];
  if (data is Map && flagged(data['mobile_reverification_required'])) {
    return true;
  }
  return false;
}
