import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  StripeConfig._();

  static const String _publishableKey = 'pk_test_51PDAIZB9QQNQNiiiG7R3OtZxqTkAQWtx7XwZz5Wjvqv1CqglwwxtrvlYyimvncWHmPr1kjAFTFce7whXay2Q3XRX00L8Lyte5K';
  static bool isInitialized = false;
  static Future<void> init() async {
    if (isInitialized) return;
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
    isInitialized = true;
  }
}