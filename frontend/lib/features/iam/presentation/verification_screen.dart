// ignore_for_file: unused_element

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../providers/auth_provider.dart';

// ── Color Palette Constants ──
const Color _navy950 = Color(0xFF03101E);
const Color _navy900 = Color(0xFF071B2D);
const Color _border = Color(0xFF103A5C);
const Color _mint = Color(0xFF14E3A4);
const Color _darkMint = Color(0xFF0A5C52);
const Color _cyan = Color(0xFF00FFD0);
const Color _slate100 = Color(0xFFF1F5F9);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate500 = Color(0xFF475569);
const Color _slate600 = Color(0xFF64748B);
const Color _errorRed = Color(0xFFEF4444);
const Color _errorText = Color(0xFFFCA5A5);

/// Fases del flujo de verificación.
enum _VerificationPhase { methodSelection, codeInput, linkWaiting }

class VerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  // OTP controllers & focus nodes
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  // Countdown timer
  Timer? _countdownTimer;
  int _secondsRemaining = 60;

  // Verification phase
  _VerificationPhase _phase = _VerificationPhase.methodSelection;
  bool _requestingMethod = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  void _handleResend() {
    ref.read(authProvider.notifier).resendVerification(widget.email);
    _startCountdown();
  }

  String get _otpCode =>
      _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 1) return email;
    return '${name[0]}***@$domain';
  }

  String _emailDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    return parts[1];
  }

  /// Selects a verification method and transitions to the appropriate phase.
  Future<void> _selectMethod(String method) async {
    setState(() => _requestingMethod = true);
    final success = await ref.read(authProvider.notifier).requestVerification(widget.email, method);
    if (!mounted) return;
    setState(() {
      _requestingMethod = false;
      if (success) {
        if (method == 'code') {
          _phase = _VerificationPhase.codeInput;
          _startCountdown();
        } else {
          _phase = _VerificationPhase.linkWaiting;
        }
      }
    });
  }

  /// Submits the OTP code for verification.
  Future<void> _submitOtpCode() async {
    final success = await ref.read(authProvider.notifier).verifyEmail(widget.email, _otpCode);
    if (!mounted) return;
    if (success) {
      context.go('/verification-success');
    }
  }

  /// Manual check after link verification (user says "Ya verifiqué").
  Future<void> _checkLinkVerification() async {
    // Re-request verification status by trying to verify with empty code
    // The backend should return user data if already verified via link
    final success = await ref.read(authProvider.notifier).verifyEmail(widget.email, '');
    if (!mounted) return;
    if (success) {
      context.go('/verification-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _navy950,
      body: Stack(
        children: [
          // ── Background orb ──
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withOpacity(0.12),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // ── Content ──
          Center(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Step indicator ──
                      _buildStepIndicator(),
                      const SizedBox(height: 32),

                      // ── Success banner ──
                      if (authState.successMessage != null) ...[
                        _buildSuccessBanner(authState.successMessage!),
                        const SizedBox(height: 20),
                      ],

                      // ── Error banner ──
                      if (authState.errorMessage != null) ...[
                        _buildErrorBanner(authState.errorMessage!),
                        const SizedBox(height: 20),
                      ],

                      // ── Main card ──
                      _buildMainCard(authState),
                      const SizedBox(height: 24),

                      // ── Footer ──
                      _buildFooter(),
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
  // STEP INDICATOR
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1 – Completed
        _buildStepCircle(
          label: 'DATOS',
          stepNumber: '1',
          isCompleted: true,
          isActive: false,
        ),
        _buildStepConnector(isCompleted: true),
        // Step 2 – Active
        _buildStepCircle(
          label: 'VERIFICAR',
          stepNumber: '2',
          isCompleted: false,
          isActive: true,
        ),
        _buildStepConnector(isCompleted: false),
        // Step 3 – Inactive
        _buildStepCircle(
          label: 'LISTO',
          stepNumber: '3',
          isCompleted: false,
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildStepCircle({
    required String label,
    required String stepNumber,
    required bool isCompleted,
    required bool isActive,
  }) {
    final bool highlighted = isCompleted || isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? _mint : _navy950,
            border: Border.all(
              color: highlighted ? _mint : _border,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: _navy950, size: 18)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      color: highlighted ? _slate100 : _slate600,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: highlighted ? _mint : _slate600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isCompleted ? _mint : _border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BANNERS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mint.withOpacity(0.1),
        border: Border.all(color: _mint.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _mint, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _slate100, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

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

  // ══════════════════════════════════════════════════════════════════
  // MAIN CARD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMainCard(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _navy900.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _navy950.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Small IronLink logo ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _slate100.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1),
            ),
            child: Image.asset(
              'assets/logo.png',
              width: 150,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          // ── Email icon container ──
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _mint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _mint.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.email_outlined,
                color: _mint,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          const Text(
            'Verifica tu correo',
            style: TextStyle(
              color: _slate100,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // ── Phase-dependent content ──
          if (_phase == _VerificationPhase.methodSelection)
            _buildMethodSelection(authState)
          else if (_phase == _VerificationPhase.codeInput)
            _buildCodeInputPhase(authState)
          else
            _buildLinkWaitingPhase(authState),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 1: METHOD SELECTION
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMethodSelection(AuthState authState) {
    final maskedEmail = _maskEmail(widget.email);

    return Column(
      children: [
        // ── Subtitle ──
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: _slate400,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Elige cómo deseas verificar tu cuenta '),
              TextSpan(
                text: maskedEmail,
                style: const TextStyle(
                  color: _mint,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Code option card ──
        _buildMethodCard(
          icon: Icons.pin_outlined,
          title: 'Código de verificación',
          subtitle: 'Recibe un código de 6 dígitos en tu correo electrónico',
          onTap: _requestingMethod ? null : () => _selectMethod('code'),
        ),
        const SizedBox(height: 12),

        // ── Link option card ──
        _buildMethodCard(
          icon: Icons.link,
          title: 'Enlace por correo',
          subtitle: 'Recibe un enlace de verificación en tu bandeja de entrada',
          onTap: _requestingMethod ? null : () => _selectMethod('link'),
        ),

        if (_requestingMethod) ...[
          const SizedBox(height: 20),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: _mint,
              strokeWidth: 2.5,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Secondary button: Volver y editar datos ──
        _buildSecondaryButton(),
      ],
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _navy950.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _mint.withOpacity(0.2)),
                ),
                child: Icon(icon, color: _mint, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _slate100,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _slate400,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _slate500, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 2: CODE INPUT (existing OTP UI)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildCodeInputPhase(AuthState authState) {
    final maskedEmail = _maskEmail(widget.email);
    final domain = _emailDomain(widget.email);

    return Column(
      children: [
        // ── Subtitle with masked email ──
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: _slate400,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: 'Ingresa el código de 6 dígitos que enviamos a ',
              ),
              TextSpan(
                text: maskedEmail,
                style: const TextStyle(
                  color: _mint,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' para activar tu cuenta.'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Info box ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _mint.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _mint.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: _mint,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _slate400,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'El código fue enviado a tu correo $domain. '
                            'Revisa también tu carpeta de spam. '
                            'El código expira en ',
                      ),
                      const TextSpan(
                        text: '10 minutos',
                        style: TextStyle(
                          color: _mint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── OTP Input ──
        _buildOtpInput(),
        const SizedBox(height: 20),

        // ── Resend row ──
        _buildResendRow(),
        const SizedBox(height: 28),

        // ── Primary button: Verificar y crear cuenta ──
        _buildPrimaryButton(authState),
        const SizedBox(height: 12),

        // ── Go back to method selection ──
        _buildBackToMethodButton(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 3: LINK WAITING
  // ══════════════════════════════════════════════════════════════════
  Widget _buildLinkWaitingPhase(AuthState authState) {
    final isLoading = authState.status == AuthStatus.loading;

    return Column(
      children: [
        const SizedBox(height: 8),

        // ── Link icon ──
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _mint.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mint.withOpacity(0.25)),
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_outlined, color: _mint, size: 36),
          ),
        ),
        const SizedBox(height: 24),

        // ── Message ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _mint.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _mint.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.outgoing_mail, color: _mint, size: 28),
              const SizedBox(height: 12),
              const Text(
                'Revisa tu correo y haz clic en el enlace de verificación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _slate100,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un enlace a ${_maskEmail(widget.email)}. '
                'Una vez hagas clic en él, regresa aquí y presiona el botón.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _slate400,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── "Ya verifiqué" button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            onPressed: isLoading ? null : _checkLinkVerification,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_mint, _darkMint],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _slate100,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Ya verifiqué mi correo ✓',
                        style: TextStyle(
                          color: _slate100,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Resend link ──
        _buildResendRow(),
        const SizedBox(height: 16),

        // ── Go back to method selection ──
        _buildBackToMethodButton(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // OTP INPUT (6 boxes)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 52,
          height: 56,
          margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: _slate100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _navy950,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _otpControllers[index].text.isNotEmpty
                      ? _mint
                      : _border,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _mint,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {}); // rebuild to update border colors
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

  // ══════════════════════════════════════════════════════════════════
  // RESEND ROW
  // ══════════════════════════════════════════════════════════════════
  Widget _buildResendRow() {
    final canResend = _secondsRemaining <= 0;
    final timerText = '0:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No recibiste el código? ',
          style: TextStyle(color: _slate400, fontSize: 13),
        ),
        GestureDetector(
          onTap: canResend ? _handleResend : null,
          child: Text(
            canResend ? 'Reenviar' : 'Reenviar ($timerText)',
            style: TextStyle(
              color: canResend
                  ? _mint
                  : _slate600,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PRIMARY BUTTON
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPrimaryButton(AuthState authState) {
    final isLoading = authState.status == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        onPressed: (_isOtpComplete && !isLoading)
            ? _submitOtpCode
            : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: (_isOtpComplete && !isLoading)
                ? const LinearGradient(
                    colors: [_mint, _darkMint],
                  )
                : LinearGradient(
                    colors: [
                      _mint.withOpacity(0.3),
                      _darkMint.withOpacity(0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _slate100,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Verificar y crear cuenta →',
                    style: TextStyle(
                      color: (_isOtpComplete && !isLoading)
                          ? _slate100
                          : _slate100.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // SECONDARY BUTTON
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: _navy950,
          side: const BorderSide(color: _border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.go('/register'),
        child: const Text(
          '← Volver y editar datos',
          style: TextStyle(
            color: _slate100,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BACK TO METHOD SELECTION BUTTON
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBackToMethodButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: _navy950,
          side: const BorderSide(color: _border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          setState(() {
            _phase = _VerificationPhase.methodSelection;
            _countdownTimer?.cancel();
            // Clear OTP fields
            for (final c in _otpControllers) {
              c.clear();
            }
          });
        },
        child: const Text(
          '← Cambiar método de verificación',
          style: TextStyle(
            color: _slate100,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // FOOTER
  // ══════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _mint,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Registro seguro · IronLink · Cifrado AES-256',
          style: TextStyle(
            color: _slate600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}