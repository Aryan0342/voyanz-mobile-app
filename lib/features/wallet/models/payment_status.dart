class PaymentStatusResponse {
  final String status;
  final String? jackpotf;
  final dynamic sessionRegistration;

  const PaymentStatusResponse({
    required this.status,
    this.jackpotf,
    this.sessionRegistration,
  });

  bool get isSuccess => status == 'succeeded';
  bool get isProcessing => status == 'processing';

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PaymentStatusResponse(
      status: data['status']?.toString() ?? 'error',
      jackpotf: data['jackpotf']?.toString(),
      sessionRegistration: data['session_registration'],
    );
  }
}
