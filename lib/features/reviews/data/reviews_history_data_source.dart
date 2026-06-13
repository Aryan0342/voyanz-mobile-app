import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:voyanz/core/config/api_endpoints.dart';

final _logger = Logger();

class ReviewsHistoryDataSource {
  final Dio _dio;

  ReviewsHistoryDataSource(this._dio);

  Future<List<dynamic>> getCustomerHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerHistory);
      return _parseHistoryResponse(response.data);
    } catch (e) {
      _logger.e('Error fetching customer history: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getProfessionalHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.professionalHistory);
      return _parseHistoryResponse(response.data);
    } catch (e) {
      _logger.e('Error fetching professional history: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCustomerReviews() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerReviews);
      return _parseReviewsResponse(response.data);
    } catch (e) {
      _logger.e('Error fetching customer reviews: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getProfessionalReviews() async {
    try {
      final response = await _dio.get(ApiEndpoints.professionalReviews);
      return _parseReviewsResponse(response.data);
    } catch (e) {
      _logger.e('Error fetching professional reviews: $e');
      rethrow;
    }
  }

  Future<void> postReview(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiEndpoints.postReview, data: body);
    _throwIfApiError(response.data, fallback: 'Post review failed');
  }

  Future<Map<String, dynamic>> getCustomerPricing() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerPricing);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        _throwIfApiError(body, fallback: 'Customer pricing failed');
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        return Map<String, dynamic>.from(body)
          ..remove('err')
          ..remove('meta');
      }
      return {};
    } catch (e) {
      _logger.e('Error fetching customer pricing: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkPromoCode(String code) async {
    final response = await _dio.post(
      ApiEndpoints.checkPromoCode,
      data: {'code': code},
    );
    final body = response.data;
    _throwIfApiError(body, fallback: 'Promo code check failed');
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return const {};
  }

  /// Parse history response handling various formats
  List<dynamic> _parseHistoryResponse(dynamic responseData) {
    _throwIfApiError(responseData, fallback: 'History request failed');
    try {
      if (responseData == null) return [];

      // Direct list response
      if (responseData is List) {
        return responseData;
      }

      // Map with 'data' key
      if (responseData is Map<String, dynamic>) {
        final histories = responseData['histories'];
        if (histories is List) {
          return histories;
        }

        final data = responseData['data'];

        // If data is already a list, return it
        if (data is List) {
          return data;
        }

        // If data is a map (single item), wrap it in a list
        if (data is Map<String, dynamic>) {
          return [data];
        }
      }

      return [];
    } catch (e) {
      _logger.e('Error parsing history response: $e, response: $responseData');
      return [];
    }
  }

  /// Parse reviews response handling various formats
  List<dynamic> _parseReviewsResponse(dynamic responseData) {
    _throwIfApiError(responseData, fallback: 'Reviews request failed');
    try {
      if (responseData == null) return [];

      // Direct list response
      if (responseData is List) {
        return responseData;
      }

      // Map with 'data' key
      if (responseData is Map<String, dynamic>) {
        for (final key in const ['reviews', 'reviewspro', 'histories']) {
          final list = responseData[key];
          if (list is List) return list;
        }

        final data = responseData['data'];

        // If data is already a list, return it
        if (data is List) {
          return data;
        }

        // If data is a map (single item), wrap it in a list
        if (data is Map<String, dynamic>) {
          return [data];
        }
      }

      return [];
    } catch (e) {
      _logger.e('Error parsing reviews response: $e, response: $responseData');
      return [];
    }
  }

  void _throwIfApiError(dynamic responseData, {required String fallback}) {
    if (responseData is! Map<String, dynamic>) return;

    final topLevelError = responseData['error'];
    if (topLevelError != null && topLevelError != false && topLevelError != 0) {
      final message =
          responseData['message']?.toString() ?? topLevelError.toString();
      throw Exception(message.trim().isEmpty ? fallback : message);
    }

    final err = responseData['err'];
    if (err == null || err == false || err == 0) return;

    if (err is Map<String, dynamic>) {
      final message =
          err['message']?.toString() ??
          err['key']?.toString() ??
          err['code']?.toString();
      throw Exception(message == null || message.trim().isEmpty
          ? fallback
          : message);
    }

    throw Exception(err.toString());
  }
}
