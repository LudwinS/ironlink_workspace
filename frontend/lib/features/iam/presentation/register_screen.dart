import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

// Color Palette Constants
const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _darkMint = AppColors.darkMint;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;
const _slate600 = AppColors.slate600;
const _errorRed = AppColors.errorRed;
const _errorText = AppColors.errorText;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  // Errores de servidor por campo
  String? _serverEmailError;
  String? _serverPhoneError;
  String? _serverPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    // Limpiar errores de servidor previos
    setState(() {
      _serverEmailError = null;
      _serverPhoneError = null;
      _serverPasswordError = null;
    });

    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (success && mounted) {
        context.go('/verification?email=${_emailController.text.trim()}');
      } else if (mounted) {
        // Extraer errores por campo del estado
        final authState = ref.read(authProvider);
        if (authState.fieldErrors != null) {
          setState(() {
            _serverEmailError = authState.fieldErrors!['email'];
            _serverPhoneError = authState.fieldErrors!['phone'];
            _serverPasswordError = authState.fieldErrors!['password'];
          });
          // Revalidar formulario para mostrar errores inline
          _formKey.currentState!.validate();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: _navy950,
      body: Stack(
        children: [
          // Orbe decorativo superior izquierdo
          Positioned(
            top: -150,
            left: -150,
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

          // Orbe decorativo inferior derecho
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withOpacity(0.06),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Contenido principal
          Center(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── STEP INDICATOR ──
                      _buildStepIndicator(),
                      const SizedBox(height: 32),

                      // ── ERROR BANNER (solo errores generales) ──
                      if (authState.errorMessage != null && authState.fieldErrors == null) ...[
                        Container(
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
                                  authState.errorMessage!,
                                  style: const TextStyle(color: _errorText, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── MAIN CARD ──
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _navy900.withOpacity(0.85),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo pequeño top-left
                              _buildCardLogo(),
                              const SizedBox(height: 20),

                              // Título y subtítulo centrados
                              const Center(
                                child: Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    color: _slate100,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(
                                child: Text(
                                  'Registro seguro · IronLink',
                                  style: TextStyle(
                                    color: _slate400,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── NOMBRE COMPLETO ──
                              _buildFieldLabel('NOMBRE COMPLETO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: _slate100),
                                decoration: _inputDecoration(
                                  hint: 'Ludwin Romero',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── CORREO ELECTRÓNICO ──
                              _buildFieldLabel('CORREO ELECTRÓNICO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: _slate100),
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  hint: 'ludwin@organizacion.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'El correo es requerido';
                                  if (!value.contains('@')) return 'Formato de correo inválido';
                                  if (_serverEmailError != null) return _serverEmailError;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── TELÉFONO ──
                              _buildFieldLabel('TELÉFONO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                style: const TextStyle(color: _slate100),
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  hint: '12345678',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'El teléfono es requerido';
                                  if (_serverPhoneError != null) return _serverPhoneError;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── CONTRASEÑA y CONFIRMAR (side by side) ──
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Contraseña
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('CONTRASEÑA'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(color: _slate100),
                                          decoration: _inputDecoration(
                                            hint: 'Mínimo 8 caracteres',
                                            icon: Icons.lock_outlined,
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: _mint.withOpacity(0.7),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'La contraseña es requerida';
                                            if (value.length < 8) return 'Debe tener al menos 8 caracteres';
                                            if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe contener al menos una mayúscula';
                                            if (!value.contains(RegExp(r'[a-z]'))) return 'Debe contener al menos una minúscula';
                                            if (!value.contains(RegExp(r'[0-9]'))) return 'Debe contener al menos un número';
                                            if (!value.contains(RegExp(r'''[!@#\$%^\&*()_+\-=\[\]{}|;:',.<>?/]'''))) return 'Debe contener al menos un carácter especial';
                                            if (_serverPasswordError != null) return _serverPasswordError;
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Confirmar contraseña
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('CONFIRMAR CONTRASEÑA'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          style: const TextStyle(color: _slate100),
                                          decoration: _inputDecoration(
                                            hint: 'Repite la contraseña',
                                            icon: Icons.lock_outlined,
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: _mint.withOpacity(0.7),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                                            if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── INDICADOR DE FUERZA DE CONTRASEÑA ──
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _passwordController,
                                builder: (context, value, _) {
                                  final password = value.text;
                                  return _PasswordStrengthIndicator(password: password);
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── TERMS CHECKBOX ──
                              _buildTermsCheckbox(),
                              const SizedBox(height: 24),

                              // ── SUBMIT BUTTON ──
                              _buildSubmitButton(isLoading),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── LINK A LOGIN ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(color: _slate400),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Inicia sesión aquí',
                              style: TextStyle(
                                color: _mint,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── FOOTER BADGE ──
                      Row(
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

  // ─── STEP INDICATOR ───────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(number: 1, label: 'DATOS', isActive: true),
        _buildStepLine(),
        _buildStep(number: 2, label: 'VERIFICAR', isActive: false),
        _buildStepLine(),
        _buildStep(number: 3, label: 'LISTO', isActive: false),
      ],
    );
  }

  Widget _buildStep({required int number, required String label, required bool isActive}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _mint : Colors.transparent,
            border: Border.all(
              color: isActive ? _mint : _border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: isActive ? Colors.white : _slate600,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? _mint : _slate600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 48,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: _border,
    );
  }

  // ─── CARD LOGO ────────────────────────────────────────────────────

  Widget _buildCardLogo() {
    return Align(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/logo.png',
        height: 70,
        fit: BoxFit.contain,
      ),
    );
  }

  // ─── FIELD LABEL ──────────────────────────────────────────────────

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _mint,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  // ─── TERMS CHECKBOX ───────────────────────────────────────────────

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
            activeColor: _mint,
            checkColor: Colors.white,
            side: const BorderSide(color: _border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: _slate400, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos de uso',
                    style: TextStyle(
                      color: _mint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de privacidad',
                    style: TextStyle(
                      color: _mint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' de IronLink'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────────────────────────

  Widget _buildSubmitButton(bool isLoading) {
    final bool enabled = !isLoading && _acceptedTerms;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.5,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        onPressed: enabled ? _submit : null,
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Crear cuenta →',
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
    );
  }

  // ─── INPUT DECORATION ─────────────────────────────────────────────

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
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
      errorStyle: const TextStyle(color: _errorText, fontSize: 12),
    );
  }
}

/// Widget privado: Indicador visual de fuerza de contraseña en tiempo real.
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'''[!@#\$%^\&*()_+\-=\[\]{}|;:',.<>?/]'''));

    final criteria = [
      hasMinLength,
      hasUppercase,
      hasLowercase,
      hasDigit,
      hasSpecial,
    ];
    final metCount = criteria.where((c) => c).length;

    // Colores de la barra según fuerza
    Color barColor;
    String strengthLabel;
    if (metCount <= 1) {
      barColor = _errorRed; // Rojo
      strengthLabel = 'Muy débil';
    } else if (metCount == 2) {
      barColor = const Color(0xFFF97316); // Naranja
      strengthLabel = 'Débil';
    } else if (metCount == 3) {
      barColor = const Color(0xFFEAB308); // Amarillo
      strengthLabel = 'Regular';
    } else if (metCount == 4) {
      barColor = const Color(0xFF22C55E); // Verde claro
      strengthLabel = 'Fuerte';
    } else {
      barColor = _mint; // Mint (paleta de la marca)
      strengthLabel = 'Muy segura';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de fuerza con 5 segmentos
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 4,
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: index < metCount
                      ? barColor
                      : _border.withOpacity(0.5),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Label de fuerza
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seguridad de la contraseña',
              style: TextStyle(color: _slate400, fontSize: 11),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                strengthLabel,
                key: ValueKey(strengthLabel),
                style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Lista de criterios con checkmarks
        _CriteriaRow(label: 'Mínimo 8 caracteres', met: hasMinLength),
        const SizedBox(height: 4),
        _CriteriaRow(label: 'Al menos una mayúscula', met: hasUppercase),
        const SizedBox(height: 4),
        _CriteriaRow(label: 'Al menos una minúscula', met: hasLowercase),
        const SizedBox(height: 4),
        _CriteriaRow(label: 'Al menos un número', met: hasDigit),
        const SizedBox(height: 4),
        _CriteriaRow(label: 'Al menos un carácter especial (!@#\$...)', met: hasSpecial),
      ],
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  final String label;
  final bool met;

  const _CriteriaRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(met),
            size: 16,
            color: met ? _mint : _slate500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: met ? _mint : _slate600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}