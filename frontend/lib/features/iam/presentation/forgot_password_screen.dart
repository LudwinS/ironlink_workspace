import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../providers/auth_provider.dart';

// ── Color Palette Constants ──
const Color _navy950 = AppColors.navy950;
const Color _navy900 = AppColors.navy900;
const Color _border = AppColors.border;
const Color _mint = AppColors.mint;
const Color _darkMint = AppColors.darkMint;
const Color _cyan = AppColors.cyan;
const Color _slate100 = AppColors.slate100;
const Color _slate400 = AppColors.slate400;
const Color _slate500 = AppColors.slate500;
const Color _slate600 = AppColors.slate600;
const Color _errorRed = AppColors.errorRed;
const Color _errorText = AppColors.errorText;

enum _RecoveryPhase { emailEntry, codeAndNewPassword, success }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  _RecoveryPhase _phase = _RecoveryPhase.emailEntry;

  // Countdown timer
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == 6;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 1) return email;
    return '${name[0]}***@$domain';
  }

  // ── Password Validation Checklist ──
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\+\-=\[\]\\\/;]'));

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecial;

  // ── Handlers ──
  Future<void> _handleRequestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un correo válido.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await ref.read(authProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      setState(() {
        _phase = _RecoveryPhase.codeAndNewPassword;
        _startCountdown();
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa los 6 dígitos del código de recuperación.')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await ref.read(authProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _otpCode,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      setState(() {
        _phase = _RecoveryPhase.success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _navy950,
      body: Stack(
        children: [
          // Background subtle orb
          Positioned(
            top: -140,
            right: -140,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          Center(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Container
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _navy900,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Icon
                            Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _mint.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _mint.withValues(alpha: 0.3)),
                                ),
                                child: Icon(
                                  _phase == _RecoveryPhase.success
                                      ? Icons.check_circle_outline
                                      : Icons.lock_reset,
                                  color: _phase == _RecoveryPhase.success ? _mint : _cyan,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error banner
                            if (authState.errorMessage != null && _phase != _RecoveryPhase.success) ...[
                              _buildErrorBanner(authState.errorMessage!),
                              const SizedBox(height: 18),
                            ],

                            // Success banner on request code
                            if (authState.successMessage != null && _phase == _RecoveryPhase.codeAndNewPassword) ...[
                              _buildSuccessBanner(authState.successMessage!),
                              const SizedBox(height: 18),
                            ],

                            // Phase Views
                            if (_phase == _RecoveryPhase.emailEntry)
                              _buildEmailEntryPhase(authState)
                            else if (_phase == _RecoveryPhase.codeAndNewPassword)
                              _buildCodeAndNewPasswordPhase(authState)
                            else
                              _buildSuccessPhase(),
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

  // ══════════════════════════════════════════════════════════════════
  // FASE 1: INGRESO DE CORREO
  // ══════════════════════════════════════════════════════════════════
  Widget _buildEmailEntryPhase(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recuperar Contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa el correo electrónico asociado a tu cuenta para enviarte un código de seguridad.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _slate400, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 28),

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
        ),
        const SizedBox(height: 24),

        // Botón Enviar Código
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          onPressed: _submitting ? null : _handleRequestCode,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_mint, _darkMint]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Enviar código de recuperación ➔',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Volver a Login
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: _slate100,
          ),
          onPressed: () => context.go('/login'),
          child: const Text('← Cancelar y volver al inicio de sesión', style: TextStyle(fontSize: 13.5)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // FASE 2: OTP + NUEVA CONTRASEÑA
  // ══════════════════════════════════════════════════════════════════
  Widget _buildCodeAndNewPasswordPhase(AuthState authState) {
    final canResend = _secondsRemaining <= 0;
    final timerText = '0:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Restablecer Contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa el código enviado a ${_maskEmail(_emailController.text.trim())} y define tu nueva clave.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _slate400, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 22),

          // ── OTP 6 Digits ──
          const Text(
            'CÓDIGO DE 6 DÍGITOS',
            style: TextStyle(
              color: _mint,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildOtpInput(),
          const SizedBox(height: 10),

          // Resend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No recibiste el código? ', style: TextStyle(color: _slate400, fontSize: 12)),
              GestureDetector(
                onTap: canResend ? _handleRequestCode : null,
                child: Text(
                  canResend ? 'Reenviar' : 'Reenviar ($timerText)',
                  style: TextStyle(
                    color: canResend ? _mint : _slate600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Nueva Contraseña ──
          const Text(
            'NUEVA CONTRASEÑA',
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
            onChanged: (v) => setState(() {}),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _mint.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'La contraseña es requerida';
              if (!_isPasswordValid) return 'Cumple con los requisitos de seguridad';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Requisitos de Contraseña
          _buildPasswordRequirements(),
          const SizedBox(height: 18),

          // ── Confirmar Contraseña ──
          const Text(
            'CONFIRMAR CONTRASEÑA',
            style: TextStyle(
              color: _mint,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _mint.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 26),

          // Botón Confirmar
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            onPressed: _submitting ? null : _handleResetPassword,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_mint, _darkMint]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Restablecer y Guardar Clave ➔',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cambiar correo o volver
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _phase = _RecoveryPhase.emailEntry;
                  _countdownTimer?.cancel();
                  for (final c in _otpControllers) {
                    c.clear();
                  }
                });
              },
              child: const Text(
                '← Cambiar correo electrónico',
                style: TextStyle(color: _cyan, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // FASE 3: ÉXITO
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSuccessPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¡Contraseña Actualizada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _mint,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu contraseña ha sido restablecida y cifrada con Argon2id. Tu cuenta está activa y lista para usar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _slate100, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 30),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          onPressed: () => context.go('/login'),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_mint, _darkMint]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: const Text(
                'Iniciar Sesión Ahora ➔',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Requisitos de Contraseña ─────────────────────────────────────────
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _navy950,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReqItem('Mínimo 8 caracteres', _hasMinLength),
          _buildReqItem('Al menos una mayúscula (A-Z)', _hasUppercase),
          _buildReqItem('Al menos una minúscula (a-z)', _hasLowercase),
          _buildReqItem('Al menos un número (0-9)', _hasNumber),
          _buildReqItem('Al menos un carácter especial (!@#\$%...)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildReqItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? _mint : _slate600,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: met ? _slate100 : _slate500,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─── OTP Input ────────────────────────────────────────────────────────
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 52,
          margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: _slate100,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _navy950,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _otpControllers[index].text.isNotEmpty ? _mint : _border,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _mint, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  // ─── Error & Success Banners ──────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.1),
        border: Border.all(color: _errorRed.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: _errorText, fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _mint.withValues(alpha: 0.1),
        border: Border.all(color: _mint.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _mint, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: _slate100, fontSize: 12.5))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _slate500),
      prefixIcon: Icon(icon, color: _mint.withValues(alpha: 0.7), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _navy950.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
