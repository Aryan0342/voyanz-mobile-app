import 'package:voyanz/core/storage/token_storage.dart';
import 'package:voyanz/features/auth/data/auth_data_source.dart';
import 'package:voyanz/features/auth/models/user.dart';

class AuthRepository {
  final AuthDataSource _dataSource;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dataSource, this._tokenStorage);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dataSource.login(email: email, password: password);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<User> getUserInfos() => _dataSource.getUserInfos();

  Future<void> logout() => _tokenStorage.clear();
}
