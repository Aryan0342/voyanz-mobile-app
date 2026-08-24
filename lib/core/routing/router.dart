import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/auth/screens/login_screen.dart';
import 'package:voyanz/features/auth/screens/forgot_password_screen.dart';
import 'package:voyanz/features/account/screens/register_screen.dart';
import 'package:voyanz/features/professionals/screens/professionals_list_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_detail_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_availability_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_account_screen.dart';
import 'package:voyanz/features/sessions/screens/video_call_screen.dart';
import 'package:voyanz/features/sessions/screens/phone_session_screen.dart';
import 'package:voyanz/features/sessions/screens/chat_session_screen.dart';
import 'package:voyanz/features/sessions/screens/session_waiting_screen.dart';
import 'package:voyanz/features/chat/screens/chat_groups_screen.dart';
import 'package:voyanz/features/chat/screens/chat_messages_screen.dart';
import 'package:voyanz/features/reviews/screens/history_screen.dart';
import 'package:voyanz/features/reviews/screens/reviews_screen.dart';
import 'package:voyanz/features/reviews/screens/pricing_screen.dart';
import 'package:voyanz/features/home/home_screen.dart';
import 'package:voyanz/features/home/screens/info_screen.dart';
import 'package:voyanz/features/home/professional_dashboard_screen.dart';
import 'package:voyanz/features/splash/splash_screen.dart';
import 'package:voyanz/features/wallet/screens/wallet_screen.dart';
import 'package:voyanz/features/wallet/screens/topup_screen.dart';
import 'package:voyanz/features/wallet/screens/payment_success_screen.dart';
import 'package:voyanz/features/appointments/screens/appointment_booking_screen.dart';

final routerProvider = Provider<RouterConfig<RouteMatchList>>((ref) {
  return _SafeRouterConfig(GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;
      final loggedIn = authState.valueOrNull != null;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (isSplashRoute) return null;
      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              // Show dashboard for professionals, professionals list for customers
              return _HomeScreenRouter();
            },
          ),
          GoRoute(
            path: '/professional/:coId',
            builder: (context, state) =>
                ProfessionalDetailScreen(coId: state.pathParameters['coId']!),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatGroupsScreen(),
          ),
          GoRoute(
            path: '/chat/:chgrId',
            builder: (context, state) => ChatMessagesScreen(
              chgrId: state.pathParameters['chgrId']!,
              seId: state.uri.queryParameters['seId'],
              coId: state.uri.queryParameters['coId'],
            ),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) =>
                const HistoryScreen(isProfessional: false),
          ),
          GoRoute(
            path: '/reviews',
            builder: (context, state) =>
                const ReviewsScreen(isProfessional: false),
          ),
          GoRoute(
            path: '/availability',
            builder: (context, state) => const ProfessionalAvailabilityScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ProfessionalClientsScreen(),
          ),
          GoRoute(
            path: '/professional-account',
            builder: (context, state) => const ProfessionalAccountScreen(),
          ),
          GoRoute(
            path: '/pricing/:coId',
            builder: (context, state) =>
                PricingScreen(coId: state.pathParameters['coId']),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/appointment-booking/:coId',
            builder: (context, state) => AppointmentBookingScreen(
              coId: state.pathParameters['coId']!,
            ),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/wallet/topup',
            builder: (context, state) => const TopUpScreen(),
          ),
          GoRoute(
            path: '/wallet/success',
            builder: (context, state) => const PaymentSuccessScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.support),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.privacy),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.about),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.terms),
          ),
          GoRoute(
            path: '/service',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.service),
          ),
          GoRoute(
            path: '/legal',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.legal),
          ),
          GoRoute(
            path: '/trust',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.trust),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) =>
                const InfoScreen(kind: InfoScreenKind.contact),
          ),
        ],
      ),
      GoRoute(
        path: '/session/wait/:type/:seId/:coId',
        builder: (context, state) => SessionWaitingScreen(
          type: state.pathParameters['type']!,
          seId: state.pathParameters['seId']!,
          coId: state.pathParameters['coId']!,
        ),
      ),
      GoRoute(
        path: '/video/:seId/:coId',
        builder: (context, state) => VideoCallScreen(
          seId: state.pathParameters['seId']!,
          coId: state.pathParameters['coId']!,
        ),
      ),
      GoRoute(
        path: '/session/phone/:seId/:coId',
        builder: (context, state) => PhoneSessionScreen(
          seId: state.pathParameters['seId']!,
          coId: state.pathParameters['coId']!,
        ),
      ),
      GoRoute(
        path: '/session/chat/:seId/:coId',
        builder: (context, state) => ChatSessionScreen(
          seId: state.pathParameters['seId']!,
          coId: state.pathParameters['coId']!,
        ),
      ),
    ],
  ));
});

/// go_router 14.x crashes with `Bad state: No element` in
/// [GoRouterDelegate.popRoute] (via `_findCurrentNavigator`) when the OS back
/// button is pressed before the router has matched any routes — e.g. right
/// after app (re)start. This wrapper catches that and reports the back button
/// as unhandled instead of throwing.
class _SafeRouterConfig implements RouterConfig<RouteMatchList> {
  _SafeRouterConfig(this._router);

  final GoRouter _router;

  late final RouterDelegate<RouteMatchList> _routerDelegate =
      _SafeRouterDelegate(_router.routerDelegate);

  @override
  RouteInformationProvider get routeInformationProvider =>
      _router.routeInformationProvider;

  @override
  RouteInformationParser<RouteMatchList> get routeInformationParser =>
      _router.routeInformationParser;

  @override
  RouterDelegate<RouteMatchList> get routerDelegate => _routerDelegate;

  @override
  BackButtonDispatcher? get backButtonDispatcher =>
      _router.backButtonDispatcher;
}

class _SafeRouterDelegate extends RouterDelegate<RouteMatchList>
    with ChangeNotifier {
  _SafeRouterDelegate(this._inner) {
    _inner.addListener(notifyListeners);
  }

  final GoRouterDelegate _inner;

  @override
  RouteMatchList get currentConfiguration => _inner.currentConfiguration;

  @override
  Widget build(BuildContext context) => _inner.build(context);

  @override
  Future<void> setNewRoutePath(RouteMatchList configuration) =>
      _inner.setNewRoutePath(configuration);

  @override
  Future<bool> popRoute() async {
    try {
      return await _inner.popRoute();
    } on StateError {
      return false;
    }
  }
}

/// Routes conditionally to Dashboard (professional) or ProfessionalsList (customer)
class _HomeScreenRouter extends ConsumerWidget {
  const _HomeScreenRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isProfessional = user?.isProfessional ?? false;
    debugPrint('Home route: role=${user?.role} isProfessional=$isProfessional');

    if (isProfessional) {
      return const ProfessionalDashboardScreen();
    }
    return const ProfessionalsListScreen();
  }
}

/// Professional clients/reviews screen (shows clients and their reviews).
class ProfessionalClientsScreen extends ConsumerWidget {
  const ProfessionalClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This can show professional reviews from clients
    return const ReviewsScreen(isProfessional: true);
  }
}
