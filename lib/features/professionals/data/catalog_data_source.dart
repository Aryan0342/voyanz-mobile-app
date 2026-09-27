import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/professionals/providers/catalog_items_provider.dart';

/// `GET /web/1.0/items` — the allowed tools, specialities and languages
/// (contract P1c). Authenticated like every other `/web/1.0` call.
class CatalogDataSource {
  final Dio _dio;

  CatalogDataSource(this._dio);

  Future<CatalogItems> getItems() async {
    final response = await _dio.get(ApiEndpoints.items);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final error = body['err'];
      if (error is Map && error.isNotEmpty) {
        final message = (error['message'] ?? error['key'] ?? 'items_failed')
            .toString();
        throw Exception(message);
      }
      return CatalogItems.fromItemsEndpoint(body);
    }
    return const CatalogItems();
  }
}
