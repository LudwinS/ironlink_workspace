// ─────────────────────────────────────────────
//  IronLink — Entry point
//  Ubicación: frontend/lib/main.dart
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const IronLinkApp());
}

class IronLinkApp extends StatelessWidget {
  const IronLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IronLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0C0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5A0),
          secondary: Color(0xFF0099FF),
          surface: Color(0xFF0F1318),
        ),
        // Fuentes: añadir en pubspec.yaml → google_fonts: ^6.0.0
        // y reemplazar fontFamily por GoogleFonts.syne() / ibmPlexMono()
        fontFamily: 'sans-serif',
      ),
      routerConfig: appRouter,
    );
  }
}