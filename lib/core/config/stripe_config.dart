import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  StripeConfig._();

  static const String _publishableKey = 'pk_live_51PDAIZB9QQNQNiiivfmjRkrvlGocsAgfUkAXM4mVi9iNjryssLfRy5r7UjYzHWSOrxgJpaF2mxXOJ4RDJxLKnm0E00QJxeTQmY';
  static bool isInitialized = false;
  static Future<void> init() async {
    if (isInitialized) return;
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
    isInitialized = true;
  }
}