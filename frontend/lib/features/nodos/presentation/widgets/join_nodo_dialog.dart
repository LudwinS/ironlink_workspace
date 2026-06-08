import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/nodos_provider.dart';
import 'dialog_text_field.dart';

const _navy900 = AppColors.navy900;
const _navy950 = AppColors.navy950;
const _border = AppColors.border;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class JoinNodoDialog extends ConsumerStatefulWidget {
  const JoinNodoDialog({super.key});

  @override
  ConsumerState<JoinNodoDialog> createState() => _JoinNodoDialogState();
}

class _JoinNodoDialogState extends ConsumerState<JoinNodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _navy900.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.link_rounded,
                            color: _cyan, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Unirse a un nodo',
                        style: TextStyle(
                          color: _slate100,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ingresa el token de acceso de 32 caracteres proporcionado por el administrador del nodo.',
                    style: TextStyle(color: _slate500, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Campo: Token
                  DialogTextField(
                    controller: _tokenCtrl,
                    label: 'Token de acceso',
                    hint: 'Ej: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
                    autofocus: true,
                    maxLength: 64,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El token de acceso es requerido';
                      }
                      if (value.trim().length < 8) {
                        return 'El token de acceso debe tener al menos 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: _slate400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cyan,
                          foregroundColor: _navy950,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          disabledBackgroundColor:
                              _cyan.withValues(alpha: 0.4),
                        ),
                        onPressed: _submitting ? null : _onSubmit,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _navy950),
                              )
                            : const Text(
                                'Unirse',
                                style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = _tokenCtrl.text.trim();
    setState(() => _submitting = true);
    final success = await ref.read(nodosProvider.notifier).joinNodo(token);
    if (mounted) {
      setState(() => _submitting = false);
      if (success) Navigator.pop(context);
    }
  }
}
