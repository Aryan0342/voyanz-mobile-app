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
    await _dio.post(ApiEndpoints.postReview, data: body);
  }

  Future<Map<String, dynamic>> getCustomerPricing() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerPricing);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>? ?? {};
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
    return response.data as Map<String, dynamic>;
  }

  /// Parse history response handling various formats
  List<dynamic> _parseHistoryResponse(dynamic responseData) {
    try {
      if (responseData == null) return [];

      // Direct list response
      if (responseData is List) {
        return responseData;
      }

      // Map with 'data' key
      if (responseData is Map<String, dynamic>) {
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
    try {
      if (responseData == null) return [];

      // Direct list response
      if (responseData is List) {
        return responseData;
      }

      // Map with 'data' key
      if (responseData is Map<String, dynamic>) {
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
}
