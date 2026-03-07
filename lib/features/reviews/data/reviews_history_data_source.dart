import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';

class ReviewsHistoryDataSource {
  final Dio _dio;

  ReviewsHistoryDataSource(this._dio);

  Future<List<dynamic>> getCustomerHistory() async {
    final response = await _dio.get(ApiEndpoints.customerHistory);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as List? ?? [];
  }

  Future<List<dynamic>> getProfessionalHistory() async {
    final response = await _dio.get(ApiEndpoints.professionalHistory);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as List? ?? [];
  }

  Future<List<dynamic>> getCustomerReviews() async {
    final response = await _dio.get(ApiEndpoints.customerReviews);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as List? ?? [];
  }

  Future<List<dynamic>> getProfessionalReviews() async {
    final response = await _dio.get(ApiEndpoints.professionalReviews);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as List? ?? [];
  }

  Future<void> postReview(Map<String, dynamic> body) async {
    await _dio.post(ApiEndpoints.postReview, data: body);
  }

  Future<Map<String, dynamic>> getCustomerPricing() async {
    final response = await _dio.get(ApiEndpoints.customerPricing);
    final body = response.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> checkPromoCode(String code) async {
    final response = await _dio.post(
      ApiEndpoints.checkPromoCode,
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }
}
