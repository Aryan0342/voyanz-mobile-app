import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/auth/screens/login_screen.dart';
import 'package:voyanz/features/account/screens/register_screen.dart';
import 'package:voyanz/features/professionals/screens/professionals_list_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_detail_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_availability_screen.dart';
import 'package:voyanz/features/sessions/screens/video_call_screen.dart';
import 'package:voyanz/features/chat/screens/chat_groups_screen.dart';
import 'package:voyanz/features/chat/screens/chat_messages_screen.dart';
import 'package:voyanz/features/reviews/screens/history_screen.dart';
import 'package:voyanz/features/reviews/screens/reviews_screen.dart';
import 'package:voyanz/features/reviews/screens/pricing_screen.dart';
import 'package:voyanz/features/home/home_screen.dart';
import 'package:voyanz/features/home/professional_dashboard_screen.dart';
import 'package:voyanz/features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.valueOrNull != null;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
            builder: (context, state) =>
                ChatMessagesScreen(chgrId: state.pathParameters['chgrId']!),
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
            path: '/pricing/:coId',
            builder: (context, state) =>
                PricingScreen(coId: state.pathParameters['coId']),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/video/:seId/:coId',
        builder: (context, state) => VideoCallScreen(
          seId: state.pathParameters['seId']!,
          coId: state.pathParameters['coId']!,
        ),
      ),
    ],
  );
});

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
