import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../providers/auth_provider.dart';

// ─── Color Palette ──────────────────────────────────────────────────────
const _navy950 = Color(0xFF03101E);
const _navy900 = Color(0xFF071B2D);
const _border = Color(0xFF103A5C);
const _mint = Color(0xFF14E3A4);
const _darkMint = Color(0xFF0A5C52);
const _cyan = Color(0xFF00FFD0);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF475569);
const _slate600 = Color(0xFF64748B);
const _errorRed = Color(0xFFEF4444);
const _errorText = Color(0xFFFCA5A5);

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
  bool _rememberMe = false;

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
            rememberMe: _rememberMe,
          );

      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _navy950,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              children: [
                // ── Left Hero Panel ──────────────────────────────────
                Expanded(
                  flex: 3,
                  child: _LeftHeroPanel(),
                ),
                // ── Right Form Panel ─────────────────────────────────
                Expanded(
                  flex: 2,
                  child: _buildRightPanel(authState),
                ),
              ],
            );
          }

          // ── Mobile: single column ──────────────────────────────────
          return _buildRightPanel(authState, showLogo: true);
        },
      ),
    );
  }

  // ─── Right Panel (Form) ───────────────────────────────────────────────
  Widget _buildRightPanel(AuthState authState, {bool showLogo = false}) {
    return Container(
      color: _navy950,
      child: Stack(
        children: [
          // Subtle gradient orb top-right
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withOpacity(0.08),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Center(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mobile-only logo
                      if (showLogo) ...[
                        _buildMobileLogo(),
                        const SizedBox(height: 36),
                      ],
                      // ── Card ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _navy900,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accede con tus credenciales IronLink',
                              style: TextStyle(color: _slate400, fontSize: 14),
                            ),
                            const SizedBox(height: 28),

                            // Error banner
                            if (authState.errorMessage != null) ...[
                              _buildErrorBanner(authState.errorMessage!),
                              const SizedBox(height: 20),
                            ],

                            // ── Form ─────────────────────────────────
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email
                                  const Text(
                                    'CORREO ELECTRÓNICO',
                                    style: TextStyle(
                                      color: _mint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      hint: 'correo@organizacion.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'El correo es requerido';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Ingresa un formato válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Password
                                  const Text(
                                    'CONTRASEÑA',
                                    style: TextStyle(
                                      color: _mint,
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
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _mint.withOpacity(0.7),
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La contraseña es requerida';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Remember me
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                          activeColor: _mint,
                                          side: const BorderSide(color: _slate400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                                        child: const Text(
                                          'Recuérdame',
                                          style: TextStyle(color: _slate400, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Primary button – Iniciar sesión
                                  _buildGradientButton(authState),
                                  const SizedBox(height: 14),

                                  // Secondary button – Registrarse
                                  _buildOutlinedButton(),
                                  const SizedBox(height: 20),

                                  // Forgot password link
                                  Center(
                                    child: Text.rich(
                                      TextSpan(
                                        text: '¿Olvidaste tu contraseña? ',
                                        style: const TextStyle(
                                          color: _slate400,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.baseline,
                                            baseline: TextBaseline.alphabetic,
                                            child: GestureDetector(
                                              onTap: () {
                                                // TODO: navigate to recovery
                                              },
                                              child: const Text(
                                                'recupérala aquí',
                                                style: TextStyle(
                                                  color: _mint,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: _border, thickness: 1)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    '— acceso seguro —',
                                    style: TextStyle(color: _slate600, fontSize: 12),
                                  ),
                                ),
                                Expanded(child: Divider(color: _border, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Footer badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _mint,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Autenticación segura · IronLink',
                                  style: TextStyle(color: _slate600, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
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

  // ─── Mobile Logo ──────────────────────────────────────────────────────
  Widget _buildMobileLogo() {
    return Image.asset(
      'assets/logo.png',
      height: 80,
      fit: BoxFit.contain,
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _errorRed.withOpacity(0.1),
        border: Border.all(color: _errorRed.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _errorText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gradient Button ──────────────────────────────────────────────────
  Widget _buildGradientButton(AuthState authState) {
    final isLoading = authState.status == AuthStatus.loading;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      onPressed: isLoading ? null : _submit,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_mint, _darkMint],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Iniciar sesión →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Outlined Button ──────────────────────────────────────────────────
  Widget _buildOutlinedButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        foregroundColor: _slate100,
      ),
      onPressed: () => context.go('/register'),
      child: const Text(
        'Registrarse',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─── Input Decoration ─────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _slate500),
      prefixIcon: Icon(icon, color: _mint.withOpacity(0.7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: _navy950.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _mint, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEFT HERO PANEL — shown only on desktop (>800px)
// ═══════════════════════════════════════════════════════════════════════════
class _LeftHeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy950, Color(0xFF00293F)],
        ),
      ),
      child: Stack(
        children: [
          // ── Grid pattern ───────────────────────────────────────────
          Positioned.fill(child: _GridPatternPainter()),

          // ── Gradient orb top-right ─────────────────────────────────
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _mint.withOpacity(0.12),
                    _mint.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Gradient orb bottom-left ───────────────────────────────
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan.withOpacity(0.07),
                    _cyan.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Image.asset(
                  'assets/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),

                const Spacer(flex: 2),

                // Hero text
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Conecta con\ntu ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const TextSpan(
                        text: 'plataforma',
                        style: TextStyle(
                          color: _mint,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const TextSpan(
                        text: '\nde forma segura.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Subtitle
                const Text(
                  'Plataforma de gestión empresarial IronLink.\nAcceso seguro con cifrado de extremo a extremo.',
                  style: TextStyle(
                    color: _slate400,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                // Feature bullets
                _buildFeatureBullet(
                  title: 'Cifrado AES-256',
                  subtitle: 'conexión encriptada siempre activa',
                ),
                const SizedBox(height: 20),
                _buildFeatureBullet(
                  title: 'Comunicación en vivo',
                  subtitle: 'con chat y participación en tiempo real',
                ),
                const SizedBox(height: 20),
                _buildFeatureBullet(
                  title: 'Acceso seguro',
                  subtitle: 'exclusivo para miembros autorizados',
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _mint,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _slate100,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _slate400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBTLE GRID PATTERN — painted behind the hero panel
// ═══════════════════════════════════════════════════════════════════════════
class _GridPatternPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _border.withOpacity(0.15)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}