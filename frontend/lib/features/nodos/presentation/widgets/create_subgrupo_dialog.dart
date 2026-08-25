import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/subgrupos_provider.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class CreateSubgrupoDialog extends ConsumerStatefulWidget {
  final String nodoId;
  const CreateSubgrupoDialog({super.key, required this.nodoId});

  static Future<bool?> show(BuildContext context, String nodoId) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => CreateSubgrupoDialog(nodoId: nodoId),
    );
  }

  @override
  ConsumerState<CreateSubgrupoDialog> createState() => _CreateSubgrupoDialogState();
}

class _CreateSubgrupoDialogState extends ConsumerState<CreateSubgrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _esPrivado = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref
        .read(subgruposProvider(widget.nodoId).notifier)
        .createSubgrupo(
          nombre: _nameCtrl.text.trim(),
          descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          esPrivado: _esPrivado,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _navy900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups_rounded, color: _cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Crear Nuevo Subgrupo',
                      style: TextStyle(
                        color: _slate100,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Nombre del Subgrupo',
                style: TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: _slate100, fontSize: 13),
                decoration: _inputDeco('Ej: Frontend, Backend, UI/UX, Equipo A'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del subgrupo' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Descripción (opcional)',
                style: TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(color: _slate100, fontSize: 13),
                decoration: _inputDeco('Objetivo o temática del subgrupo...'),
              ),
              const SizedBox(height: 16),

              // Switch privado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _navy950,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _esPrivado ? Icons.lock_rounded : Icons.public_rounded,
                      color: _esPrivado ? _cyan : _slate400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _esPrivado ? 'Subgrupo Privado' : 'Subgrupo Público',
                            style: const TextStyle(color: _slate100, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _esPrivado ? 'Solo miembros invitados' : 'Cualquier miembro del nodo puede unirse',
                            style: const TextStyle(color: _slate500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _esPrivado,
                      activeThumbColor: _cyan,
                      onChanged: (val) => setState(() => _esPrivado = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: _slate400)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: _navy950,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _navy950))
                        : const Text('Crear Subgrupo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _slate500, fontSize: 13),
      filled: true,
      fillColor: _navy950,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cyan)),
    );
  }
}
