import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voyanz/core/config/stripe_config.dart';
import 'package:voyanz/core/routing/router.dart';
import 'package:voyanz/core/theme/app_theme.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/chat/providers/chat_realtime_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StripeConfig.init();
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

class VoyanzApp extends ConsumerStatefulWidget {
  const VoyanzApp({super.key});

  @override
  ConsumerState<VoyanzApp> createState() => _VoyanzAppState();
}

class _VoyanzAppState extends ConsumerState<VoyanzApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;

    final isActive = state == AppLifecycleState.resumed;
    final ws = ref.read(webSocketServiceProvider);
    ws.setAppActive(isActive);

    if (isActive && ref.read(authStateProvider).valueOrNull != null) {
      unawaited(ws.connect());
      ref.read(chatRealtimeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Listen for auth state changes and initialize WebSocket when user logs in
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null && previous?.valueOrNull == null) {
        // User just logged in
        ref.read(webSocketServiceProvider).connect();
        // Ensure chat realtime listeners are registered while logged in
        ref.read(chatRealtimeProvider);
      } else if (next.valueOrNull == null && previous?.valueOrNull != null) {
        // User just logged out
        ref.read(webSocketServiceProvider).disconnect();
        // Dispose chat realtime listeners
        ref.invalidate(chatRealtimeProvider);
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
