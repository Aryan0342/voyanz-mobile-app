import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final isLoggedIn = await ref
        .read(authStateProvider.notifier)
        .restoreSession();
    if (!mounted) return;
    context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepIndigo,
      body: Center(
        child: Image.asset(
          'assets/images/voyanz-logo.png',
          width: 170,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
