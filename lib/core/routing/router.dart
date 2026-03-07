import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';
import 'package:voyanz/features/auth/screens/login_screen.dart';
import 'package:voyanz/features/account/screens/register_screen.dart';
import 'package:voyanz/features/professionals/screens/professionals_list_screen.dart';
import 'package:voyanz/features/professionals/screens/professional_detail_screen.dart';
import 'package:voyanz/features/sessions/screens/video_call_screen.dart';
import 'package:voyanz/features/chat/screens/chat_groups_screen.dart';
import 'package:voyanz/features/chat/screens/chat_messages_screen.dart';
import 'package:voyanz/features/reviews/screens/history_screen.dart';
import 'package:voyanz/features/reviews/screens/reviews_screen.dart';
import 'package:voyanz/features/reviews/screens/pricing_screen.dart';
import 'package:voyanz/features/home/home_screen.dart';
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
            builder: (context, state) => const ProfessionalsListScreen(),
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
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/reviews',
            builder: (context, state) => const ReviewsScreen(),
          ),
          GoRoute(
            path: '/pricing',
            builder: (context, state) => const PricingScreen(),
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
