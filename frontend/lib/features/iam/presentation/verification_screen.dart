import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../providers/auth_provider.dart';

class VerificationScreen extends ConsumerWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF001524), // Fondo: Deep Tech Navy 950
      body: Stack(
        children: [
          // Orbe de fondo brillante con los colores de la paleta
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00BFA5).withOpacity(0.12), // Mint Green Glow
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          
          Center(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // INTEGRACIÓN DEL LOGO ORIGINAL
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF1E3A52), width: 1),
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 180,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    const Center(
                      child: Text(
                        '¡Revisa tu correo!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Hemos enviado un enlace de activación a:',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        email.isNotEmpty ? email : 'tu dirección de correo registrada',
                        style: const TextStyle(
                          color: Color(0xFF00BFA5), // Mint Green
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Mensaje de éxito al reenviar
                    if (authState.successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF00BFA5), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.successMessage!,
                                style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Tarjeta Informativa (Glassmorphism con colores de paleta)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002238).withOpacity(0.85), // Card: Dark Tech Navy 900
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF1E3A52), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Instrucciones de activación:',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _bulletInstruction('Abre tu correo y busca el mensaje de IronLink.'),
                          const SizedBox(height: 12),
                          _bulletInstruction('Haz clic en el enlace adjunto para activar la cuenta (validez de 24 horas).'),
                          const SizedBox(height: 12),
                          _bulletInstruction('Una vez activada, regresa a esta aplicación e inicia sesión.'),
                          const SizedBox(height: 32),

                          // Botón Reenviar Correo
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001524),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFF1E3A52)),
                              ),
                              elevation: 0,
                            ),
                            onPressed: authState.status == AuthStatus.loading
                                ? null
                                : () => ref.read(authProvider.notifier).resendVerification(email),
                            child: authState.status == AuthStatus.loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Reenviar Correo de Activación',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BFA5)),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón para volver a Iniciar Sesión (Gradiente Mint Green)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      onPressed: () => context.go('/login'),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)], // Gradiente de la paleta
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Regresar al Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      );
  }

  Widget _bulletInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_right_alt, color: Color(0xFF00BFA5), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}