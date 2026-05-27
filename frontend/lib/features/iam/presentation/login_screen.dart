import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  IronLink — Login Screen
//  Ubicación: frontend/lib/features/iam/presentation/login_screen.dart
// ─────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // ── Paleta IronLink ──────────────────────────
  static const _bg0    = Color(0xFF0A0C0F);
  static const _bg1    = Color(0xFF0F1318);
  static const _border2 = Color(0x1FFFFFFF);
  static const _accent2 = Color(0xFF0099FF);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text2   = Color(0xFF7A8A9E);
  static const _text3   = Color(0xFF3D4E62);
  static const _mono    = 'monospace';
  static const _danger  = Color(0xFFFF4757);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: Row(
        children: [
          // ── LEFT: Branding ──────────────────
          Expanded(child: _LeftPanel()),

          // ── RIGHT: Form ─────────────────────
          Container(
            width: 520,
            decoration: const BoxDecoration(
              color: _bg1,
              border: Border(left: BorderSide(color: _border2)),
            ),
            child: Center(
              child: SizedBox(
                width: 360,
                child: _buildForm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Iniciar sesión',
          style: TextStyle(
            color: _text1,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Accede a tu espacio de comunicación',
          style: TextStyle(color: _text2, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),

        // Username field
        _FieldLabel('Usuario'),
        const SizedBox(height: 8),
        _InputField(
          controller: _userCtrl,
          icon: Icons.person_outline,
          hint: 'tu_usuario',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),

        // Password field
        _FieldLabel('Contraseña'),
        const SizedBox(height: 8),
        _InputField(
          controller: _passCtrl,
          icon: Icons.lock_outline,
          hint: '••••••••',
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _text3,
              size: 18,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 28),

        // Login button
        _PrimaryButton(
          label: 'Ingresar →',
          onTap: () {
            final user = _userCtrl.text.trim();
            final pass = _passCtrl.text;

            if (user.isEmpty) {
              _showError(context, 'Ingresa tu nombre de usuario');
              return;
            }
            if (RegExp(r'\s').hasMatch(user)) {
              _showError(context, 'El usuario no puede tener espacios');
              return;
            }
            if (pass.isEmpty) {
              _showError(context, 'Ingresa tu contraseña');
              return;
            }
            if (pass.length < 8) {
              _showError(context, 'La contraseña debe tener al menos 8 caracteres');
              return;
            }
            // TODO: llamar iam_repository.dart para auth real
            context.go('/home');
          },
        ),
        const SizedBox(height: 24),

        // Divider
        Row(children: [
          const Expanded(child: Divider(color: _border2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('acceso seguro',
                style: TextStyle(
                    color: _text3, fontSize: 11, fontFamily: _mono)),
          ),
          const Expanded(child: Divider(color: _border2)),
        ]),
        const SizedBox(height: 24),

        // Badge
        _UgbBadge(label: 'Autenticación cifrada · IronLink'),
        const SizedBox(height: 24),

        // Register link
        Center(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: _text3, fontSize: 12, fontFamily: _mono),
              children: [
                const TextSpan(text: '¿No tienes cuenta? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'Regístrate aquí',
                      style: TextStyle(
                          color: _accent2,
                          fontSize: 12,
                          fontFamily: _mono),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  LEFT PANEL — Branding
// ─────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  static const _accent  = Color(0xFF00E5A0);
  static const _accent2 = Color(0xFF0099FF);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text2   = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid overlay
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        // Glow
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.2),
                radius: 1.2,
                colors: [
                  _accent.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_accent, _accent2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('🔗', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      letterSpacing: -1, color: _text1,
                    ),
                    children: [
                      TextSpan(text: 'Iron'),
                      TextSpan(text: 'Link',
                          style: TextStyle(color: _accent)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 60),

              // Headline
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 42, fontWeight: FontWeight.w700,
                    letterSpacing: -1, color: _text1, height: 1.18,
                  ),
                  children: [
                    TextSpan(text: 'Conecta con\ntu '),
                    TextSpan(
                      text: 'equipo',
                      style: TextStyle(color: _accent),
                    ),
                    TextSpan(text: '\nen tiempo real.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 420,
                child: Text(
                  'Plataforma de comunicación y videollamadas. Chatea, colabora y conéctate con tu equipo desde cualquier lugar.',
                  style: TextStyle(color: _text2, fontSize: 16, height: 1.7),
                ),
              ),
              const SizedBox(height: 52),

              // Features
              ...[
                ('Videollamadas HD', 'audio y video de alta calidad siempre activos'),
                ('Canales y chats', 'organiza conversaciones por temas y equipos'),
                ('Compartir pantalla', 'colabora en tiempo real con tu equipo'),
              ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: _text2, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${f.$1} ',
                          style: const TextStyle(
                              color: _text1,
                              fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: '— ${f.$2}'),
                      ],
                    ),
                  ),
                ]),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF7A8A9E),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  static const _bg2    = Color(0xFF141920);
  static const _border2 = Color(0x1FFFFFFF);
  static const _accent  = Color(0xFF00E5A0);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text2   = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
          color: _text1, fontFamily: 'monospace', fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: _bg2,
        hintText: hint,
        hintStyle: const TextStyle(color: _text2, fontFamily: 'monospace'),
        prefixIcon: Icon(icon, color: _text2, size: 18),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  static const _accent = Color(0xFF00E5A0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _UgbBadge extends StatelessWidget {
  final String label;
  const _UgbBadge({required this.label});

  static const _bg2    = Color(0xFF141920);
  static const _accent = Color(0xFF00E5A0);
  static const _text2  = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: _text2, fontSize: 12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  Grid painter (decorative background)
// ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FFFFFF)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}