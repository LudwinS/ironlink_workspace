import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/iam/presentation/login_screen.dart';
import '../../features/iam/presentation/register_screen.dart';
import '../../features/iam/presentation/verification_screen.dart';
import '../../features/iam/presentation/verification_success_screen.dart';
import '../../features/nodos/presentation/dashboard_screen.dart';
import '../../features/iam/providers/auth_provider.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier();
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.notify();
  });
  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verification' ||
          state.matchedLocation == '/verification-success';

      if (!isLoggedIn) {
        if (!isGoingToAuth) {
          return '/login';
        }
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
});