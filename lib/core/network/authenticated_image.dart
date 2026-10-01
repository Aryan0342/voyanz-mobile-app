import 'package:voyanz/core/config/env.dart';
import 'package:voyanz/core/storage/token_storage.dart';

/// Headers for an image served by our own API.
///
/// Since 2026-09-29 `GET /api/1.0/chat/image/:chme_id` requires
/// `Authorization: Bearer` + `x-api-key` and answers `token_mandatory` as JSON
/// without them, so an unauthenticated `Image.network` renders a broken image
/// instead of the photo.
///
/// Returns an empty map for anything not served by our API: a third-party
/// avatar host must never be sent the user's bearer token.
Map<String, String> imageAuthHeaders(String url) {
  if (!isOwnApiUrl(url)) return const {};
  final token = TokenStorage.cachedAccessToken;
  final key = EnvConfig.current.apiKey;
  return {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    if (key != null && key.isNotEmpty) 'x-api-key': key,
  };
}

/// Whether [url] points at the configured API origin. A relative path is ours
/// by definition, since it is resolved against the API base URL.
bool isOwnApiUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final target = Uri.tryParse(trimmed);
  if (target == null) return false;
  if (!target.hasScheme) return true;
  final base = Uri.tryParse(EnvConfig.current.baseUrl);
  if (base == null) return false;
  return target.host.toLowerCase() == base.host.toLowerCase();
}
