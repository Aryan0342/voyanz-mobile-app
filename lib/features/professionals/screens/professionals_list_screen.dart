import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/professionals/providers/professionals_provider.dart';

class ProfessionalsListScreen extends ConsumerWidget {
  const ProfessionalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionalsAsync = ref.watch(professionalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Professionals')),
      body: professionalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pros) {
          if (pros.isEmpty) {
            return const Center(child: Text('No professionals found.'));
          }
          return ListView.builder(
            itemCount: pros.length,
            itemBuilder: (_, i) {
              final pro = pros[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: pro.avatar != null
                      ? NetworkImage(pro.avatar!)
                      : null,
                  child: pro.avatar == null
                      ? Text(
                          pro.displayName.isNotEmpty ? pro.displayName[0] : '?',
                        )
                      : null,
                ),
                title: Text(pro.displayName),
                subtitle: Text(pro.specialty ?? ''),
                trailing: pro.isOnline == true
                    ? const Icon(Icons.circle, color: Colors.green, size: 12)
                    : const Icon(Icons.circle, color: Colors.grey, size: 12),
                onTap: () => context.push('/professional/${pro.coId}'),
              );
            },
          );
        },
      ),
    );
  }
}
