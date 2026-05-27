import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: IronLinkApp(),
    ),
  );
}

class IronLinkApp extends StatelessWidget {
  const IronLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IronLink Portal',
      debugShowCheckedModeBanner: false,
      
      // Enrutador de GoRouter
      routerConfig: AppRouter.router,
      
      // Tema Oscuro Premium Integrado con la Paleta de la Marca (Mint Green & Tech Navy)
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        
        // Colores de la paleta oficial cargados
        scaffoldBackgroundColor: const Color(0xFF001524), // Fondo: Deep Tech Navy 950
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BFA5), // Mint Green
          secondary: Color(0xFF00E5FF), // Cyan/Teal
          surface: Color(0xFF002238), // Card: Dark Tech Navy 900
          error: Color(0xFFEF4444), // Red 500
        ),
        
        // Estilo de tipografía
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFFF1F5F9)), // Slate 100
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)), // Slate 400
        ),
        
        // Estilo de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}