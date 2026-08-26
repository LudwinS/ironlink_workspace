import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../data/nodos_repository.dart';
import '../../data/subgrupos_repository.dart';
import '../../providers/nodos_provider.dart';
import '../../providers/subgrupos_provider.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _cyan = AppColors.cyan;
const _mint = AppColors.mint;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class AssignMembersDialog extends ConsumerStatefulWidget {
  final String nodoId;
  final Subgrupo subgrupo;

  const AssignMembersDialog({
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
      builder: (_) => AssignMembersDialog(
        nodoId: nodoId,
        subgrupo: subgrupo,
      ),
    );
  }

  @override
  ConsumerState<AssignMembersDialog> createState() => _AssignMembersDialogState();
}

class _AssignMembersDialogState extends ConsumerState<AssignMembersDialog> {
  final _searchCtrl = TextEditingController();
  List<NodoMiembro> _allMembers = [];
  Set<String> _existingMemberIds = {};
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() {
        _filterQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(nodosRepositoryProvider);
      final subRepo = ref.read(subgruposRepositoryProvider);

      final members = await repo.fetchMiembros(widget.nodoId);
      final subMembers = await subRepo.fetchSubgrupoMiembros(
        nodoId: widget.nodoId,
        subgrupoId: widget.subgrupo.id,
      );

      final existingIds = subMembers.map((m) => m.userId).toSet();

      if (mounted) {
        setState(() {
          _allMembers = members;
          _existingMemberIds = existingIds;
          _selectedUserIds = Set.from(existingIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAssignment() async {
    final toAssign = _selectedUserIds.difference(_existingMemberIds).toList();
    if (toAssign.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = true);
    final success = await ref
        .read(subgruposProvider(widget.nodoId).notifier)
        .asignarMiembros(
          subgrupoId: widget.subgrupo.id,
          userIds: toAssign,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Se asignaron ${toAssign.length} miembros a "${widget.subgrupo.nombre}"'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al asignar miembros al subgrupo'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _allMembers.where((m) {
      if (_filterQuery.isEmpty) return true;
      return m.name.toLowerCase().contains(_filterQuery) ||
          m.email.toLowerCase().contains(_filterQuery);
    }).toList();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 650),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────────
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
                      child: const Icon(Icons.group_add_rounded, color: _cyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asignar Integrantes al Subgrupo',
                            style: TextStyle(
                              color: _slate100,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '# ${widget.subgrupo.nombre}',
                            style: const TextStyle(
                              color: _cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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

              // ── Search & Batch Selection ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: _slate100, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o correo...',
                        hintStyle: const TextStyle(color: _slate500, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: _slate400, size: 18),
                        suffixIcon: _filterQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: _slate400, size: 16),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: _navy950,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${_selectedUserIds.length} de ${_allMembers.length} seleccionados',
                          style: const TextStyle(color: _slate400, fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedUserIds.addAll(_allMembers.map((m) => m.userId));
                            });
                          },
                          child: const Text('Marcar todos', style: TextStyle(color: _cyan, fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedUserIds = Set.from(_existingMemberIds);
                            });
                          },
                          child: const Text('Restablecer', style: TextStyle(color: _slate400, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),

              // ── Member List with Multi-Checkbox ──────────────────────
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: _cyan),
                        ),
                      )
                    : filteredMembers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No se encontraron miembros para asignar.',
                                style: TextStyle(color: _slate500, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filteredMembers.length,
                            separatorBuilder: (_, _) => const Divider(color: _border, height: 1),
                            itemBuilder: (context, idx) {
                              final member = filteredMembers[idx];
                              final isSelected = _selectedUserIds.contains(member.userId);
                              final isExisting = _existingMemberIds.contains(member.userId);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: _cyan,
                                checkColor: _navy950,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                secondary: UserAvatar(
                                  avatarUrl: member.avatarUrl,
                                  avatarColor: member.avatarColor,
                                  name: member.name,
                                  size: 32,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _slate100,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isExisting) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _mint.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: _mint.withValues(alpha: 0.3)),
                                        ),
                                        child: const Text(
                                          'MIEMBRO',
                                          style: TextStyle(
                                            color: _mint,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  member.email,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _slate500, fontSize: 11),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedUserIds.add(member.userId);
                                    } else {
                                      _selectedUserIds.remove(member.userId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
              const Divider(color: _border, height: 1),

              // ── Action Buttons ──────────────────────────────────────
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: _navy950,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _saveAssignment,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _navy950),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Asignando...' : 'Asignar Integrantes',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
