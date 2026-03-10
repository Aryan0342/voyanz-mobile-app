import 'package:voyanz/core/config/mock_backend.dart';
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
    if (kUseMockBackend) {
      return _mockLogin(email: email, password: password);
    }
    final response = await _dataSource.login(email: email, password: password);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // Some login payloads omit/encode role inconsistently.
    // Resolve canonical user data from /user/infos when possible.
    try {
      final userInfos = await _dataSource.getUserInfos();
      return LoginResponse(
        user: userInfos,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        agency: response.agency,
        preferences: response.preferences,
        i18n: response.i18n,
      );
    } catch (_) {
      // Fallback to login payload if user infos request fails.
      return response;
    }
  }

  Future<LoginResponse> _mockLogin({
    required String email,
    required String password,
  }) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (email != kMockLoginEmail || password != kMockLoginPassword) {
      throw Exception(
        'Invalid credentials. Use $kMockLoginEmail / $kMockLoginPassword',
      );
    }

    const mockUser = User(
      coId: 'mock-user-001',
      email: kMockLoginEmail,
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

  Future<User> getUserInfos() async {
    if (kUseMockBackend) {
      return const User(
        coId: 'mock-user-001',
        email: kMockLoginEmail,
        firstName: 'Test',
        lastName: 'User',
        role: 'customer',
      );
    }
    return _dataSource.getUserInfos();
  }

  Future<void> logout() => _tokenStorage.clear();
}
