// ─────────────────────────────────────────────
//  IronLink — App Router
//  Ubicación: frontend/lib/core/router/app_router.dart
//
//  Requiere: go_router (añadir en pubspec.yaml)
//    dependencies:
//      go_router: ^13.0.0
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/iam/presentation/login_screen.dart';
import '../../features/iam/presentation/register_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
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
      path: '/home',
      builder: (context, state) => const Scaffold(
        backgroundColor: Color(0xFF0A0C0F),
        body: Center(
          child: Text(
            '🔗  IronLink — Home (próximamente)',
            style: TextStyle(color: Color(0xFF00E5A0), fontSize: 20),
          ),
        ),
      ),
    ),
    // TODO: añadir rutas de canales, videollamadas, etc.
  ],
);