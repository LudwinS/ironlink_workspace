import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────
//  IronLink — Register Screen (Pasos 1 → 2 → 3)
//  Ubicación: frontend/lib/features/iam/presentation/register_screen.dart
// ─────────────────────────────────────────────
//
//  Este archivo maneja los 3 pasos de registro en un solo widget
//  con un PageController interno para transicionar entre pasos.
//  Paso 1 → Datos personales
//  Paso 2 → Verificación de correo  (ver verification_screen.dart si
//            prefieres separarlo)
//  Paso 3 → Cuenta creada
//

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0; // 0,1,2

  // Paso 1 controllers
  final _nameCtrl    = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _userCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _pass2Ctrl   = TextEditingController();

  bool _termsChecked = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  int _passStrength = 0;

  // Paso 2 - código de 6 dígitos
  final List<TextEditingController> _codeCtrl =
      List.generate(6, (_) => TextEditingController());

  // ── Paleta ──────────────────────────────────
  static const _bg0    = Color(0xFF0A0C0F);
  static const _bg1    = Color(0xFF0F1318);
  static const _bg2    = Color(0xFF141920);
  static const _border2 = Color(0x1FFFFFFF);
  static const _accent  = Color(0xFF00E5A0);
  static const _accent2 = Color(0xFF0099FF);
  static const _danger  = Color(0xFFFF4757);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text2   = Color(0xFF7A8A9E);

  @override
  void dispose() {
    _nameCtrl.dispose(); _lastCtrl.dispose(); _userCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose();
    for (var c in _codeCtrl) { c.dispose(); }
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _calcStrength(String v) {
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    setState(() => _passStrength = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(
        children: [
          // Grid decorativo
          CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
          // Glow verde arriba
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.2,
                  colors: [_accent.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          // Card centrada
          Center(
            child: _buildCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 560,
      decoration: BoxDecoration(
        color: _bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 80,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      padding: const EdgeInsets.all(52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepsIndicator(current: _step),
          const SizedBox(height: 36),
          _Logo(),
          const SizedBox(height: 24),
          if (_step == 0) ..._buildStep1(),
          if (_step == 1) ..._buildStep2(),
          if (_step == 2) ..._buildStep3(),
        ],
      ),
    );
  }

  // ── PASO 1: Datos ─────────────────────────
  List<Widget> _buildStep1() {
    return [
      const Text('Crear cuenta',
          style: TextStyle(color: _text1, fontSize: 26,
              fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      const Text('Regístrate para unirte a IronLink',
          style: TextStyle(color: _text2, fontSize: 14)),
      const SizedBox(height: 28),

      // Nombre / Apellidos
      Row(children: [
        Expanded(child: _LabeledField(
            label: 'Nombre', ctrl: _nameCtrl,
            icon: Icons.person_outline, hint: 'Tu nombre')),
        const SizedBox(width: 16),
        Expanded(child: _LabeledField(
            label: 'Apellido', ctrl: _lastCtrl,
            icon: Icons.person_outline, hint: 'Tu apellido')),
      ]),
      const SizedBox(height: 4),

      // Usuario
      _LabeledField(
          label: 'Nombre de usuario', ctrl: _userCtrl,
          icon: Icons.alternate_email, hint: 'tu.usuario'),
      const SizedBox(height: 4),

      // Email
      _LabeledField(
          label: 'Correo electrónico', ctrl: _emailCtrl,
          icon: Icons.mail_outline,
          hint: 'tu@correo.com',
          keyboard: TextInputType.emailAddress),
      const SizedBox(height: 4),

      // Passwords row
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledField(
                  label: 'Contraseña', ctrl: _passCtrl,
                  icon: Icons.lock_outline,
                  hint: '••••••••', obscure: _obscure1,
                  onChanged: _calcStrength,
                  suffix: _EyeToggle(
                    show: _obscure1,
                    onTap: () => setState(() => _obscure1 = !_obscure1),
                  )),
              const SizedBox(height: 6),
              _StrengthBar(strength: _passStrength),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _LabeledField(
            label: 'Confirmar contraseña', ctrl: _pass2Ctrl,
            icon: Icons.lock_outline, hint: '••••••••',
            obscure: _obscure2,
            suffix: _EyeToggle(
              show: _obscure2,
              onTap: () => setState(() => _obscure2 = !_obscure2),
            ))),
      ]),
      const SizedBox(height: 20),

      // Terms
      GestureDetector(
        onTap: () => setState(() => _termsChecked = !_termsChecked),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 18, height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _termsChecked ? _accent : _bg2,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: _termsChecked ? _accent : _border2),
            ),
            child: _termsChecked
                ? const Icon(Icons.check, size: 12, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: _text2, fontSize: 12, height: 1.5),
                children: [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(text: 'Términos de uso',
                      style: TextStyle(color: _accent)),
                  TextSpan(text: ' y la '),
                  TextSpan(text: 'Política de privacidad',
                      style: TextStyle(color: _accent)),
                  TextSpan(text: ' de IronLink'),
                ],
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // CTA
      _PrimaryButton(
        label: 'Continuar →',
        onTap: () {
          final name  = _nameCtrl.text.trim();
          final last  = _lastCtrl.text.trim();
          final user  = _userCtrl.text.trim();
          final email = _emailCtrl.text.trim();
          final pass  = _passCtrl.text;
          final pass2 = _pass2Ctrl.text;

          if (name.isEmpty) { _showError('Ingresa tu nombre'); return; }
          if (last.isEmpty) { _showError('Ingresa tu apellido'); return; }
          if (user.isEmpty) { _showError('Ingresa un nombre de usuario'); return; }
          if (RegExp(r'[^a-zA-Z0-9._\-]').hasMatch(user)) {
            _showError('Usuario solo puede tener letras, números, puntos o guiones');
            return;
          }
          if (email.isEmpty) { _showError('Ingresa tu correo electrónico'); return; }
          if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$').hasMatch(email)) {
            _showError('Correo electrónico no válido');
            return;
          }
          if (pass.length < 8) {
            _showError('La contraseña debe tener al menos 8 caracteres');
            return;
          }
          if (pass != pass2) {
            _showError('Las contraseñas no coinciden');
            return;
          }
          if (!_termsChecked) {
            _showError('Debes aceptar los términos de uso');
            return;
          }
          setState(() => _step = 1);
        },
      ),
      const SizedBox(height: 18),

      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Ya tienes cuenta? ',
                style: TextStyle(color: _text2, fontSize: 13)),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('Inicia sesión aquí',
                  style: TextStyle(color: _accent, fontSize: 13)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _Badge(label: 'Registro exclusivo · IronLink · Acceso seguro'),
    ];
  }

  // ── PASO 2: Verificar correo ─────────────
  List<Widget> _buildStep2() {
    return [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text('📩', style: TextStyle(fontSize: 28)),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Verifica tu correo',
          style: TextStyle(color: _text1, fontSize: 26,
              fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: const TextStyle(color: _text2, fontSize: 14, height: 1.5),
          children: [
            const TextSpan(text: 'Ingresa el código de 6 dígitos enviado a '),
            TextSpan(
              text: _emailCtrl.text.isNotEmpty
                  ? _emailCtrl.text
                  : 'tu correo',
              style: const TextStyle(
                  color: _accent2, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),

      // Info box
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _accent2.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent2.withOpacity(0.15)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ℹ️', style: TextStyle(fontSize: 16)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Revisa tu bandeja de entrada o spam. El código expira en 10 minutos.',
                style: TextStyle(color: _text2, fontSize: 12,
                    fontFamily: 'monospace', height: 1.6),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),

      // 6 boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          return Container(
            width: 62, height: 68,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: TextField(
              controller: _codeCtrl[i],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: _accent, fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace'),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _bg2,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent, width: 1.5)),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 10),
      Center(
        child: RichText(
          text: const TextSpan(
            style: TextStyle(color: _text2, fontSize: 12,
                fontFamily: 'monospace'),
            children: [
              TextSpan(text: '¿No recibiste el código? '),
              TextSpan(text: 'Reenviar',
                  style: TextStyle(color: _accent2)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),

      _PrimaryButton(
          label: 'Verificar y crear cuenta →',
          onTap: () {
            final code = _codeCtrl.map((c) => c.text).join();
            if (_codeCtrl.any((c) => c.text.isEmpty)) {
              _showError('Ingresa el código completo de 6 dígitos');
              return;
            }
            if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
              _showError('El código solo puede contener números');
              return;
            }
            // TODO: verificar código contra backend
            setState(() => _step = 2);
          }),
      const SizedBox(height: 14),
      _SecondaryButton(
          label: '← Volver y editar datos',
          onTap: () => setState(() => _step = 0)),
      const SizedBox(height: 4),
      _Badge(label: 'Verificación segura · IronLink'),
    ];
  }

  // ── PASO 3: Cuenta creada ─────────────────
  List<Widget> _buildStep3() {
    return [
      Center(
        child: Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: _accent.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 40),
            ],
          ),
          child: const Center(
            child: Text('✅', style: TextStyle(fontSize: 42)),
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Center(
        child: Text('¡Cuenta creada!',
            style: TextStyle(color: _text1, fontSize: 28,
                fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      ),
      const SizedBox(height: 10),
      const Center(
        child: Text(
          'Tu cuenta IronLink ha sido activada. Ya puedes\ncomunicarte con tu equipo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _text2, fontSize: 14, height: 1.6),
        ),
      ),
      const SizedBox(height: 32),

      // Summary card
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: _bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            _SummaryRow('Nombre',
                '${_nameCtrl.text} ${_lastCtrl.text}'),
            _SummaryRow('Usuario', _userCtrl.text, accent: true),
            _SummaryRow('Correo', _emailCtrl.text),
            _SummaryRow('Estado', '● Activo', accent: true),
          ],
        ),
      ),
      const SizedBox(height: 28),

      _PrimaryButton(
        label: 'Ir a IronLink →',
        onTap: () => context.go('/login'),
      ),
      const SizedBox(height: 20),
      _Badge(label: 'Registro exitoso · IronLink'),
    ];
  }
}

// ─────────────────────────────────────────────
//  Sub-widgets de registro
// ─────────────────────────────────────────────

class _StepsIndicator extends StatelessWidget {
  final int current;
  const _StepsIndicator({required this.current});

  static const _accent  = Color(0xFF00E5A0);
  static const _bg2     = Color(0xFF141920);
  static const _border2 = Color(0x1FFFFFFF);
  static const _text3   = Color(0xFF3D4E62);
  static const _labels  = ['Datos', 'Verificar', 'Listo'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isDone   = i < current;
        final isActive = i == current;
        return Row(children: [
          Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? _accent
                    : isDone
                        ? _accent.withOpacity(0.15)
                        : _bg2,
                border: Border.all(
                  color: isActive
                      ? _accent
                      : isDone
                          ? _accent.withOpacity(0.3)
                          : _border2,
                ),
              ),
              child: Center(
                child: Text(
                  isDone ? '✓' : '${i + 1}',
                  style: TextStyle(
                    color: isActive
                        ? Colors.black
                        : isDone
                            ? _accent
                            : _text3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[i],
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isActive ? _accent : _text3,
                letterSpacing: 0.5,
              ),
            ),
          ]),
          if (i < 2)
            Container(
              width: 52, height: 1,
              margin: const EdgeInsets.only(bottom: 18),
              color: i < current ? _accent : _border2,
            ),
        ]);
      }),
    );
  }
}

class _Logo extends StatelessWidget {
  static const _accent  = Color(0xFF00E5A0);
  static const _accent2 = Color(0xFF0099FF);
  static const _text1   = Color(0xFFE8EDF5);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accent, _accent2],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🔗', style: TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      RichText(
        text: const TextSpan(
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              letterSpacing: -0.5, color: _text1),
          children: [
            TextSpan(text: 'Iron'),
            TextSpan(text: 'Link', style: TextStyle(color: _accent)),
          ],
        ),
      ),
    ]);
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboard;
  final void Function(String)? onChanged;

  const _LabeledField({
    required this.label,
    required this.ctrl,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboard = TextInputType.text,
    this.onChanged,
  });

  static const _bg2     = Color(0xFF141920);
  static const _border2 = Color(0x1FFFFFFF);
  static const _accent  = Color(0xFF00E5A0);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text2   = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              color: _text2, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: const TextStyle(
              color: _text1, fontFamily: 'monospace', fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bg2,
            hintText: hint,
            hintStyle: const TextStyle(
                color: _text2, fontFamily: 'monospace'),
            prefixIcon: Icon(icon, color: _text2, size: 16),
            suffixIcon: suffix,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _EyeToggle extends StatelessWidget {
  final bool show;
  final VoidCallback onTap;
  const _EyeToggle({required this.show, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF3D4E62),
        size: 18,
      ),
      onPressed: onTap,
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final int strength;
  const _StrengthBar({required this.strength});

  static const _bg3    = Color(0xFF1C2330);
  static const _accent = Color(0xFF00E5A0);
  static const _warn   = Color(0xFFFFA500);
  static const _danger = Color(0xFFFF4757);
  static const _text3  = Color(0xFF3D4E62);

  Color _segColor(int segIndex) {
    if (segIndex >= strength) return _bg3;
    if (strength == 1) return _danger;
    if (strength == 2) return _warn;
    return _accent;
  }

  String get _label {
    const labels = ['', 'Débil', 'Regular', 'Buena', 'Fuerte'];
    return labels[strength];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: _segColor(i),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(_label,
            style: const TextStyle(
                color: _text3, fontSize: 11, fontFamily: 'monospace')),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String rowKey;
  final String value;
  final bool accent;
  const _SummaryRow(this.rowKey, this.value, {this.accent = false});

  static const _border = Color(0x11FFFFFF);
  static const _accent  = Color(0xFF00E5A0);
  static const _text1   = Color(0xFFE8EDF5);
  static const _text3   = Color(0xFF3D4E62);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rowKey.toUpperCase(),
              style: const TextStyle(
                  color: _text3, fontSize: 11,
                  fontFamily: 'monospace', letterSpacing: 0.5)),
          Text(value,
              style: TextStyle(
                  color: accent ? _accent : _text1,
                  fontSize: 13, fontFamily: 'monospace')),
        ],
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  static const _border2 = Color(0x1FFFFFFF);
  static const _text2   = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _text2,
          side: const BorderSide(color: _border2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  static const _bg2    = Color(0xFF141920);
  static const _accent = Color(0xFF00E5A0);
  static const _text2  = Color(0xFF7A8A9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            boxShadow: [
              BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: _text2, fontSize: 12)),
      ]),
    );
  }
}

// Grid painter compartido
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x04FFFFFF)
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