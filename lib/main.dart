import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:voyanz/core/config/stripe_config.dart';
import 'package:voyanz/core/routing/router.dart';
import 'package:voyanz/core/theme/app_theme.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/auth/providers/user_session_reset.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/providers/websocket_provider.dart';
import 'package:voyanz/features/chat/providers/chat_realtime_provider.dart';
import 'package:voyanz/features/sessions/providers/sessions_realtime_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads month/day names and clock conventions for every locale, so
  // `DateFormat` can follow the language the user picked in-app.
  await initializeDateFormatting();
  // await StripeConfig.init();
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
  const VoyanzApp({super.key, this.initializeStripe = true});

  final bool initializeStripe;

  @override
  ConsumerState<VoyanzApp> createState() => _VoyanzAppState();
}

class _VoyanzAppState extends ConsumerState<VoyanzApp>
    with WidgetsBindingObserver {
  /// The account whose data the providers currently hold.
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initializeStripe) {
      _initStripe();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initStripe() async {
    try {
      await StripeConfig.init().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Stripe init timed out'),
      );
    } catch (e) {
      debugPrint('Stripe init failed: $e');
    }
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
      ref.read(sessionsRealtimeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(languageProvider);
    // Keeps `DateFormat` (wallet history, chat timestamps) on the same language
    // as the rest of the UI.
    Intl.defaultLocale = language;

    // Listen for auth state changes and initialize WebSocket when user logs in
    ref.listen(authStateProvider, (previous, next) {
      // Compare settled identities only: a loading state (session restore,
      // profile refresh) is not an account change.
      if (!next.isLoading) {
        final nextUserId = next.valueOrNull?.coId;
        if (_lastUserId != null && nextUserId != _lastUserId) {
          resetUserScopedState(ref);
        }
        _lastUserId = nextUserId;
      }

      if (next.valueOrNull != null && previous?.valueOrNull == null) {
        // User just logged in
        ref.read(webSocketServiceProvider).connect();
        // Ensure chat realtime listeners are registered while logged in
        ref.read(chatRealtimeProvider);
        ref.read(sessionsRealtimeProvider);
      } else if (next.valueOrNull == null && previous?.valueOrNull != null) {
        // User just logged out
        ref.read(webSocketServiceProvider).disconnect();
        // Dispose chat realtime listeners
        ref.invalidate(chatRealtimeProvider);
        ref.invalidate(sessionsRealtimeProvider);
      }
    });

    return MaterialApp.router(
      title: 'Voyanz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      // Keep Flutter's own widgets (date pickers, text-selection menus,
      // semantic labels) in the language the user picked in-app.
      locale: Locale(language),
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
