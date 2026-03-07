import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(customerPricingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pricing) {
          if (pricing.isEmpty) {
            return const Center(child: Text('No pricing information.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: pricing.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toString()),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
