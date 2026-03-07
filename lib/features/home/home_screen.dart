import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

/// Bottom-navigation shell that wraps most authenticated screens.
class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.search, label: 'Explore'),
    (icon: Icons.chat_bubble_outline, label: 'Chat'),
    (icon: Icons.history, label: 'History'),
    (icon: Icons.star_outline, label: 'Reviews'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/reviews')) return 3;
    if (location.startsWith('/pricing') || location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  void _onTap(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/chat');
      case 2:
        context.go('/history');
      case 3:
        context.go('/reviews');
      case 4:
        context.go('/pricing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

/// Simple profile/account placeholder accessible from the profile tab.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 8),
              Text(user!.email!),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
