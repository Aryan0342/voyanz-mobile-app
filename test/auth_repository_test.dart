import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyanz/core/storage/token_storage.dart';
import 'package:voyanz/features/auth/data/auth_data_source.dart';
import 'package:voyanz/features/auth/data/auth_repository.dart';
import 'package:voyanz/features/auth/models/user.dart';

class _FakeAuthDataSource extends AuthDataSource {
  _FakeAuthDataSource()
    : _loginResponse = LoginResponse(
        user: const User(
          coId: 'login-user',
          role: 'customer',
          email: 'login@example.com',
        ),
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
      ),
      _userInfo = const User(
        coId: 'info-user',
        role: 'professional',
        email: 'info@example.com',
      ),
      super(Dio());

  final LoginResponse _loginResponse;
  final User _userInfo;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    return _loginResponse;
  }

  @override
  Future<User> getUserInfos() async {
    return _userInfo;
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? _access;
  String? _refresh;

  @override
  Future<String?> get accessToken async => _access;

  @override
  Future<String?> get refreshToken async => _refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  test(
    'login stores tokens and returns canonical user infos payload',
    () async {
      final ds = _FakeAuthDataSource();
      final storage = _FakeTokenStorage();
      final repo = AuthRepository(ds, storage);

      final response = await repo.login(email: 'u@x.com', password: 'secret');

      expect(response.accessToken, 'access-123');
      expect(await storage.accessToken, 'access-123');
      expect(await storage.refreshToken, 'refresh-123');
      expect(response.user.coId, 'info-user');
      expect(response.user.role, 'professional');
    },
  );
}
