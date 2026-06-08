import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../core/theme/app_colors.dart';
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

class VerificationSuccessScreen extends ConsumerStatefulWidget {
  const VerificationSuccessScreen({super.key});

  @override
  ConsumerState<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState
    extends ConsumerState<VerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkAnimCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _checkAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkScale = CurvedAnimation(
      parent: _checkAnimCtrl,
      curve: Curves.elasticOut,
    );
    _checkOpacity = CurvedAnimation(
      parent: _checkAnimCtrl,
      curve: Curves.easeIn,
    );
    // Start the animation after a short delay for a pleasant entrance
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkAnimCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userData = authState.verifiedUserData;

    final userName = userData?['name'] ?? authState.username ?? 'Usuario';
    final userEmail = userData?['email'] ?? authState.email ?? '';
    final userCarnet = userData?['carnet'] ?? '';
    final userStatus = userData?['status'] ?? 'Activo';

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
                color: _mint.withValues(alpha: 0.12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Step indicator (all completed) ──
                      _buildStepIndicator(),
                      const SizedBox(height: 32),

                      // ── Main card ──
                      _buildMainCard(
                        userName: userName,
                        userEmail: userEmail,
                        userCarnet: userCarnet,
                        userStatus: userStatus,
                      ),
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
  // STEP INDICATOR — all 3 steps complete, step 3 active
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(
          label: 'DATOS',
          stepNumber: '1',
          isCompleted: true,
          isActive: false,
        ),
        _buildStepConnector(isCompleted: true),
        _buildStepCircle(
          label: 'VERIFICAR',
          stepNumber: '2',
          isCompleted: true,
          isActive: false,
        ),
        _buildStepConnector(isCompleted: true),
        _buildStepCircle(
          label: 'LISTO',
          stepNumber: '3',
          isCompleted: false,
          isActive: true,
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
                      color: highlighted ? _navy950 : _slate600,
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
  // MAIN CARD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMainCard({
    required String userName,
    required String userEmail,
    required String userCarnet,
    required String userStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _navy900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _navy950.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── IronLink logo ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _slate100.withValues(alpha: 0.04),
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
          const SizedBox(height: 28),

          // ── Animated checkmark circle ──
          _buildAnimatedCheckmark(),
          const SizedBox(height: 28),

          // ── Title ──
          const Text(
            '¡Cuenta creada!',
            style: TextStyle(
              color: _slate100,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // ── Subtitle ──
          const Text(
            'Tu cuenta de IronLink ha sido activada exitosamente. Ya puedes acceder a tus nodos de trabajo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _slate400,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // ── User data card ──
          _buildUserDataCard(
            userName: userName,
            userEmail: userEmail,
            userCarnet: userCarnet,
            userStatus: userStatus,
          ),
          const SizedBox(height: 28),

          // ── Gradient button: Ir a mis nodos ──
          _buildPrimaryButton(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ANIMATED CHECKMARK
  // ══════════════════════════════════════════════════════════════════
  Widget _buildAnimatedCheckmark() {
    return AnimatedBuilder(
      animation: _checkAnimCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _checkScale.value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: _checkOpacity.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _mint.withValues(alpha: 0.12),
          border: Border.all(color: _mint.withValues(alpha: 0.4), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: _mint.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: _mint,
            size: 42,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // USER DATA CARD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildUserDataCard({
    required String userName,
    required String userEmail,
    required String userCarnet,
    required String userStatus,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _navy950.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _buildDataRow(label: 'NOMBRE', value: userName, isFirst: true),
          if (userCarnet.isNotEmpty)
            _buildDataRow(
              label: 'CARNET',
              value: userCarnet,
              valueColor: _cyan,
            ),
          _buildDataRow(label: 'CORREO', value: userEmail),
          _buildStatusRow(label: 'ESTADO', status: userStatus, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: _border, width: 0.5),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slate500,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? _slate100,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String status,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: _border, width: 0.5),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slate500,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                status,
                style: const TextStyle(
                  color: _mint,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PRIMARY BUTTON
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        onPressed: () => context.go('/login'),
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
            child: const Text(
              'Ir a mis nodos →',
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
          'Registro exitoso · IronLink',
          style: TextStyle(
            color: _slate600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

