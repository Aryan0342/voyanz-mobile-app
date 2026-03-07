import 'package:voyanz/core/storage/token_storage.dart';
import 'package:voyanz/features/auth/data/auth_data_source.dart';
import 'package:voyanz/features/auth/models/user.dart';

// TODO: Remove this flag and the mock branch once the real backend is available.
const _useMockLogin = true;
const _testEmail = 'test@voyanz.com';
const _testPassword = 'Test123!';

class AuthRepository {
  final AuthDataSource _dataSource;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dataSource, this._tokenStorage);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    if (_useMockLogin) {
      return _mockLogin(email: email, password: password);
    }
    final response = await _dataSource.login(email: email, password: password);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<LoginResponse> _mockLogin({
    required String email,
    required String password,
  }) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (email != _testEmail || password != _testPassword) {
      throw Exception('Invalid credentials. Use test@voyanz.com / Test123!');
    }

    const mockUser = User(
      coId: 'mock-user-001',
      email: _testEmail,
      firstName: 'Test',
      lastName: 'User',
      role: 'customer',
    );

    final response = LoginResponse(
      user: mockUser,
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );

    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    return response;
  }

  Future<User> getUserInfos() => _dataSource.getUserInfos();

  Future<void> logout() => _tokenStorage.clear();
}
