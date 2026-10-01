import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over [FlutterSecureStorage] for auth tokens.
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// The last access token this process read or wrote.
  ///
  /// Secure storage is async, but `Image.network` needs its headers when the
  /// widget builds. Every authenticated request already reads the token, so
  /// this is warm by the time any image is rendered; it is only ever a cache
  /// of what secure storage holds, never the source of truth.
  static String? _cachedAccess;

  /// Null until the first read or write, and after [clear].
  static String? get cachedAccessToken => _cachedAccess;

  Future<String?> get accessToken async {
    final value = await _storage.read(key: _accessKey);
    _cachedAccess = value;
    return value;
  }

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    _cachedAccess = accessToken;
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    _cachedAccess = null;
    await _storage.deleteAll();
  }
}
