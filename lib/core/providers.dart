import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/network/api_client.dart';
import 'package:voyanz/core/storage/token_storage.dart';

/// Global token storage provider.
final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

/// Configured Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient.create(tokenStorage);
});
