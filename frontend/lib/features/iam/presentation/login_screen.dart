import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF001524), // Fondo: Deep Tech Navy 950
      body: Stack(
        children: [
          // Orbes brillantes de fondo con los colores de la paleta
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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

                    // Alerta de Error
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tarjeta Principal (Glassmorphism con colores de paleta)
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'CORREO ELECTRÓNICO',
                              style: TextStyle(
                                color: Color(0xFF00BFA5), // Mint Green
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                hint: 'correo@organizacion.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'El correo es requerido';
                                if (!value.contains('@')) return 'Ingresa un formato válido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              'CONTRASEÑA',
                              style: TextStyle(
                                color: Color(0xFF00BFA5), // Mint Green
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outlined,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF00BFA5).withOpacity(0.7),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'La contraseña es requerida';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Botón de Enviar (Gradiente con colores de la marca)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                              ),
                              onPressed: authState.status == AuthStatus.loading ? null : _submit,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)], // Gradiente Mint Green a Dark Mint
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  height: 52,
                                  alignment: Alignment.center,
                                  child: authState.status == AuthStatus.loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enlace hacia Registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes una cuenta? ',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'Regístrate aquí',
                            style: TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      prefixIcon: Icon(icon, color: const Color(0xFF00BFA5).withOpacity(0.7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF001524).withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A52)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}