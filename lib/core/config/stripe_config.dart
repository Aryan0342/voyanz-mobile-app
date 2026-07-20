import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  StripeConfig._();

  static const String _publishableKey = 'pk_test_51PDAIZB9QQNQNiiiG7R3OtZxqTkAQWtx7XwZz5Wjvqv1CqglwwxtrvlYyimvncWHmPr1kjAFTFce7whXay2Q3XRX00L8Lyte5K';

  static Future<void> init() async {
    Stripe.publishableKey = _publishableKey;
  }
}
