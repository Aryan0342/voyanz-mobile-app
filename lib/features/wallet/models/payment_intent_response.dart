class PaymentIntentResponse {
  final String clientSecret;

  const PaymentIntentResponse({required this.clientSecret});

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PaymentIntentResponse(
      clientSecret: data['clientSecret']?.toString() ?? '',
    );
  }
}
