import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/routing/router.dart';
import 'package:voyanz/core/theme/app_theme.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: VoyanzApp()));
}

class VoyanzApp extends ConsumerWidget {
  const VoyanzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen for auth state changes and initialize WebSocket when user logs in
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null && previous?.valueOrNull == null) {
        // User just logged in
        ref.read(webSocketServiceProvider).connect();
      } else if (next.valueOrNull == null && previous?.valueOrNull != null) {
        // User just logged out
        ref.read(webSocketServiceProvider).disconnect();
      }
    });

    return MaterialApp.router(
      title: 'Voyanz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
