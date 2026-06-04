import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/iam/presentation/login_screen.dart';
import '../../features/iam/presentation/register_screen.dart';
import '../../features/iam/presentation/verification_screen.dart';
import '../../features/iam/presentation/verification_success_screen.dart';
import '../../features/nodos/presentation/dashboard_screen.dart';
import '../security/secure_vault.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await SecureVault.hasSession();
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verification' ||
          state.matchedLocation == '/verification-success';

      if (!isLoggedIn) {
        if (!isGoingToAuth) return '/login';
      } else {
        if (isGoingToAuth && state.matchedLocation != '/verification') {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/verification-success',
        builder: (context, state) => const VerificationSuccessScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}