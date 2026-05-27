import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/iam/presentation/login_screen.dart';
import '../../features/iam/presentation/register_screen.dart';
import '../../features/iam/presentation/verification_screen.dart';
import '../security/secure_vault.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/register', // Iniciamos en registro según las instrucciones del usuario
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await SecureVault.hasSession();
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/verification';

      if (!isLoggedIn) {
        if (!isGoingToAuth) return '/register';
      } else {
        if (isGoingToAuth && state.matchedLocation != '/verification') return '/home';
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
        path: '/home',
        builder: (context, state) => const HomeDashboard(),
      ),
    ],
  );
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001524), // Slate Navy 950
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF002238), // Slate Navy 900
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1E3A52), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF00BFA5)), // Mint Green
              const SizedBox(height: 24),
              const Text(
                '¡Inicio de Sesión Exitoso!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bienvenido a la plataforma de IronLink.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await SecureVault.clearAuthData();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}