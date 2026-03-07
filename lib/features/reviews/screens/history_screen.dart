import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/reviews/providers/reviews_provider.dart';

class HistoryScreen extends ConsumerWidget {
  /// If true, shows professional history; otherwise customer history.
  final bool isProfessional;

  const HistoryScreen({super.key, this.isProfessional = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      isProfessional ? professionalHistoryProvider : customerHistoryProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i] as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(item['se_type']?.toString() ?? 'Session'),
                subtitle: Text(item['se_date']?.toString() ?? ''),
                trailing: Text(item['se_status']?.toString() ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
