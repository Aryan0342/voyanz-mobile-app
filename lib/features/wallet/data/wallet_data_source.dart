import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/wallet/models/payment_intent_response.dart';
import 'package:voyanz/features/wallet/models/payment_status.dart';
import 'package:voyanz/features/wallet/models/balance_response.dart';

final _logger = Logger();

class WalletDataSource {
  final Dio _dio;

  WalletDataSource(this._dio);

  Future<Map<String, dynamic>> fetchPricing() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerPricing);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        _throwIfApiError(body, fallback: 'Failed to fetch pricing');
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        return Map<String, dynamic>.from(body)
          ..remove('err')
          ..remove('meta');
      }
      return {};
    } catch (e) {
      _logger.e('Error fetching pricing: $e');
      rethrow;
    }
  }

  Future<PaymentIntentResponse> createPaymentIntent({
    required String item,
    String? code,
  }) async {
    try {
      final data = <String, dynamic>{'item': item};
      if (code != null && code.isNotEmpty) data['code'] = code;

      final response = await _dio.post(
        ApiEndpoints.stripePaymentIntent,
        data: data,
      );
      final body = response.data;
      _throwIfApiError(body, fallback: 'Failed to create payment intent');
      return PaymentIntentResponse.fromJson(
        body is Map<String, dynamic> ? body : <String, dynamic>{},
      );
    } catch (e) {
      _logger.e('Error creating payment intent: $e');
      rethrow;
    }
  }

  Future<PaymentStatusResponse> confirmPaymentStatus(String pi) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.payreturnStatusById(pi),
      );
      final body = response.data;
      _throwIfApiError(body, fallback: 'Failed to confirm payment');
      return PaymentStatusResponse.fromJson(
        body is Map<String, dynamic> ? body : <String, dynamic>{},
      );
    } catch (e) {
      _logger.e('Error confirming payment: $e');
      rethrow;
    }
  }

  Future<BalanceResponse> checkBalance({
    required String professionalId,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkBalance,
        data: {'professionalId': professionalId, 'type': type},
      );
      final body = response.data;
      _throwIfApiError(body, fallback: 'Failed to check balance');
      return BalanceResponse.fromJson(
        body is Map<String, dynamic> ? body : <String, dynamic>{},
      );
    } catch (e) {
      _logger.e('Error checking balance: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchHistory({
    int skip = 0,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.customerHistory,
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (search.isNotEmpty) 'search': search,
        },
      );
      final body = response.data;
      _throwIfApiError(body, fallback: 'Failed to fetch history');
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{};
    } catch (e) {
      _logger.e('Error fetching history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkPromoCode(String code) async {
    try {
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
      return const <String, dynamic>{};
    } catch (e) {
      _logger.e('Error checking promo code: $e');
      rethrow;
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
      throw Exception(
        message == null || message.trim().isEmpty ? fallback : message,
      );
    }

    throw Exception(err.toString());
  }
}
