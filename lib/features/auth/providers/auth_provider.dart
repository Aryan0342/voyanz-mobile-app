import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/providers.dart';
import 'package:voyanz/features/auth/data/auth_data_source.dart';
import 'package:voyanz/features/auth/data/auth_repository.dart';
import 'package:voyanz/features/auth/models/agency.dart';
import 'package:voyanz/features/auth/models/user.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authDataSourceProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Holds current authenticated user; null when logged out.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      return AuthNotifier(ref, ref.watch(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final AuthRepository _repo;
  Future<bool>? _restoreFuture;

  AuthNotifier(this._ref, this._repo) : super(const AsyncValue.data(null)) {
    restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _repo.login(email: email, password: password);
      _ref.read(agencyProvider.notifier).state = response.agency;
      return response.user;
    });
  }

  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getUserInfos());
  }

  Future<bool> restoreSession() {
    return _restoreFuture ??= _restoreSessionImpl();
  }

  Future<bool> _restoreSessionImpl() async {
    try {
      final hasStoredSession = await _repo.hasStoredSession();
      if (!hasStoredSession) {
        state = const AsyncValue.data(null);
        return false;
      }

      state = const AsyncValue.loading();
      final user = await _repo.getUserInfos();
      state = AsyncValue.data(user);
      return true;
    } catch (_) {
      await _repo.logout();
      _ref.read(agencyProvider.notifier).state = null;
      state = const AsyncValue.data(null);
      return false;
    } finally {
      _restoreFuture = null;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.read(agencyProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

/// Provides agency branding after login (cached from last login).
final agencyProvider = StateProvider<Agency?>((_) => null);
