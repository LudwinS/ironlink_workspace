import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/subgrupos_repository.dart';
import '../../providers/subgrupos_provider.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class EditSubgrupoDialog extends ConsumerStatefulWidget {
  final String nodoId;
  final Subgrupo subgrupo;

  const EditSubgrupoDialog({
    super.key,
    required this.nodoId,
    required this.subgrupo,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String nodoId,
    required Subgrupo subgrupo,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => EditSubgrupoDialog(
        nodoId: nodoId,
        subgrupo: subgrupo,
      ),
    );
  }

  @override
  ConsumerState<EditSubgrupoDialog> createState() => _EditSubgrupoDialogState();
}

class _EditSubgrupoDialogState extends ConsumerState<EditSubgrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subgrupo.nombre);
    _descCtrl = TextEditingController(text: widget.subgrupo.descripcion ?? '');
  }

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
        .updateSubgrupo(
          subgrupoId: widget.subgrupo.id,
          nombre: _nameCtrl.text.trim(),
          descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Subgrupo "${_nameCtrl.text.trim()}" actualizado en caliente'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el subgrupo'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 480,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _navy900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: _cyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editar Subgrupo',
                              style: TextStyle(
                                color: _slate100,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Actualización de nombre y descripción en caliente',
                              style: TextStyle(
                                color: _slate500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _slate400, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _border, height: 1),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre del Subgrupo *',
                        style: TextStyle(
                          color: _slate100,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: _slate100, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ej. Frontend Lead, Equipo Backend',
                          hintStyle: const TextStyle(color: _slate500, fontSize: 13),
                          filled: true,
                          fillColor: _navy950,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _cyan),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripción (opcional)',
                        style: TextStyle(
                          color: _slate100,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: _slate100, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Describe el propósito de este subgrupo...',
                          hintStyle: const TextStyle(color: _slate500, fontSize: 13),
                          filled: true,
                          fillColor: _navy950,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _cyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _border, height: 1),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _navy950),
                              )
                            : const Text(
                                'Guardar Cambios',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
