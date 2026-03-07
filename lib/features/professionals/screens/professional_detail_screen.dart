import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalDetailScreen extends ConsumerWidget {
  final String coId;

  const ProfessionalDetailScreen({super.key, required this.coId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(professionalDetailProvider(coId));

    return Scaffold(
      appBar: AppBar(title: const Text('Professional')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pro) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: pro.avatar != null
                        ? NetworkImage(pro.avatar!)
                        : null,
                    child: pro.avatar == null
                        ? Text(
                            pro.displayName.isNotEmpty
                                ? pro.displayName[0]
                                : '?',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    pro.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (pro.specialty != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      pro.specialty!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (pro.rating != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(pro.rating!.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (pro.description != null && pro.description!.isNotEmpty) ...[
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(pro.description!),
                  const SizedBox(height: 24),
                ],
                if (pro.pricePerMinute != null)
                  _infoRow('Price/min', '${pro.pricePerMinute} €'),
                if (pro.phone != null) _infoRow('Phone', pro.phone!),
                if (pro.email != null) _infoRow('Email', pro.email!),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Navigate to session/call creation once endpoint is ready
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Start Session'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
