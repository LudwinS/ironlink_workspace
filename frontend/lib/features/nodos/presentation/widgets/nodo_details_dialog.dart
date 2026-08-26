import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/nodos_repository.dart';
import '../../providers/nodos_provider.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;
const _slate600 = AppColors.slate600;

class NodoDetailsDialog extends ConsumerStatefulWidget {
  final Nodo nodo;
  const NodoDetailsDialog({super.key, required this.nodo});

  @override
  ConsumerState<NodoDetailsDialog> createState() => _NodoDetailsDialogState();
}

class _NodoDetailsDialogState extends ConsumerState<NodoDetailsDialog> {
  List<NodoMiembro>? _miembros;
  List<NodoBaneo>? _baneados;
  bool _loading = true;
  bool _loadingBaneados = false;
  bool _updating = false;
  String? _error;
  Timer? _refreshTimer;
  int _activeTab = 0; // 0 = Participantes, 1 = Baneados

  @override
  void initState() {
    super.initState();
    _fetchMiembros();
    // Iniciar bucle de actualización periódica para el tab activo
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_activeTab == 0) {
        _fetchMiembros(silent: true);
      } else {
        _fetchBaneados(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMiembros({bool silent = false}) async {
    if (!silent) {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    }
    try {
      final repo = ref.read(nodosRepositoryProvider);
      final miembros = await repo.fetchMiembros(widget.nodo.id);
      if (mounted) {
        setState(() {
          _miembros = miembros;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchBaneados({bool silent = false}) async {
    if (!silent) {
      if (mounted) {
        setState(() {
          _loadingBaneados = true;
          _error = null;
        });
      }
    }
    try {
      final repo = ref.read(nodosRepositoryProvider);
      final baneados = await repo.fetchBaneados(widget.nodo.id);
      if (mounted) {
        setState(() {
          _baneados = baneados;
          _loadingBaneados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loadingBaneados = false;
        });
      }
    }
  }

  Future<void> _changeRole(String targetUserId, String newRol) async {
    setState(() {
      _updating = true;
    });
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.updateMiembroRol(
        nodoId: widget.nodo.id,
        userId: targetUserId,
        newRol: newRol,
      );
      // Recargar miembros
      await _fetchMiembros(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol actualizado a $newRol exitosamente', style: const TextStyle(color: Colors.white)),
            backgroundColor: _mint.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _kickMember(String targetUserId, String name) async {
    setState(() {
      _updating = true;
    });
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.kickMiembro(widget.nodo.id, targetUserId);
      await _fetchMiembros(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario $name expulsado exitosamente', style: const TextStyle(color: Colors.white)),
            backgroundColor: _mint.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _banMember(String targetUserId, String name) async {
    setState(() {
      _updating = true;
    });
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.banMiembro(widget.nodo.id, targetUserId);
      await _fetchMiembros(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario $name baneado exitosamente', style: const TextStyle(color: Colors.white)),
            backgroundColor: _mint.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _unbanUser(String targetUserId, String name) async {
    setState(() {
      _updating = true;
    });
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.unbanMiembro(widget.nodo.id, targetUserId);
      await _fetchBaneados(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baneo de $name revocado exitosamente', style: const TextStyle(color: Colors.white)),
            backgroundColor: _mint.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    Color bg;
    switch (role.toUpperCase()) {
      case 'OWNER':
        color = const Color(0xFFFBBF24); // Amber
        bg = const Color(0xFFFBBF24).withValues(alpha: 0.15);
        break;
      case 'ADMIN':
        color = _cyan;
        bg = _cyan.withValues(alpha: 0.15);
        break;
      default:
        color = _slate400;
        bg = _slate400.withValues(alpha: 0.15);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navy900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('¿Eliminar nodo?', style: TextStyle(color: _slate100, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el nodo "${widget.nodo.nombre}"? Esta acción no se puede deshacer y desconectará a todos los miembros.',
          style: const TextStyle(color: _slate400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _slate400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(nodosProvider.notifier).deleteNodo(widget.nodo.id);
            },
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
        if (index == 1) {
          _fetchBaneados();
        } else {
          _fetchMiembros();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _mint.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? _mint.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _mint : _slate400,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildBaneadosList() {
    if (_loadingBaneados && _baneados == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_baneados == null || _baneados!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No hay usuarios baneados en este nodo.',
            style: TextStyle(color: _slate500, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _baneados!.length,
      separatorBuilder: (_, _) => const Divider(color: _border, height: 1),
      itemBuilder: (context, index) {
        final baneo = _baneados![index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                baneo.name.isNotEmpty ? baneo.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(
            baneo.name,
            style: const TextStyle(
              color: _slate100,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Por: ${baneo.creadoPorNombre ?? "Admin"}',
            style: const TextStyle(
              color: _slate500,
              fontSize: 11,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.settings_backup_restore_rounded, color: _mint, size: 18),
            tooltip: 'Desbanear usuario',
            onPressed: () => _unbanUser(baneo.userId, baneo.name),
          ),
        );
      },
    );
  }

  Widget _buildMembersList(String currentUserEmail, bool isCurrentUserOwner, String currentUserNodeRole, bool isGlobalAdmin) {
    if (_loading && _miembros == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_miembros == null || _miembros!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No hay participantes en este nodo.',
            style: TextStyle(color: _slate500, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _miembros!.length,
      separatorBuilder: (_, _) => const Divider(color: _border, height: 1),
      itemBuilder: (context, index) {
        final member = _miembros![index];
        final isSelf = member.email == currentUserEmail;
        final nameLabel = isSelf ? '${member.name} (Tú)' : member.name;

        // Check if current user can manage this specific member
        bool canManage = false;
        if (!isSelf) {
          if (isGlobalAdmin || currentUserNodeRole == 'OWNER') {
            canManage = true;
          } else if (currentUserNodeRole == 'ADMIN') {
            canManage = member.rol.toUpperCase() == 'MEMBER';
          }
        }

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSelf ? [_mint, _cyan] : [_slate500, _slate600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isSelf ? _navy950 : _slate100,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(
            nameLabel,
            style: const TextStyle(
              color: _slate100,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            member.email,
            style: const TextStyle(
              color: _slate500,
              fontSize: 11,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleBadge(member.rol),
              if (canManage) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: _slate400, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: _navy900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _border),
                  ),
                  onSelected: (action) {
                    if (action == 'ADMIN') {
                      _changeRole(member.userId, 'ADMIN');
                    } else if (action == 'MEMBER') {
                      _changeRole(member.userId, 'MEMBER');
                    } else if (action == 'KICK') {
                      _kickMember(member.userId, member.name);
                    } else if (action == 'BAN') {
                      _banMember(member.userId, member.name);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (currentUserNodeRole == 'OWNER' || isGlobalAdmin) ...[
                      PopupMenuItem(
                        value: 'ADMIN',
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: _cyan, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              member.rol == 'ADMIN' ? '✓ Administrador' : 'Hacer Administrador',
                              style: const TextStyle(color: _slate100, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'MEMBER',
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, color: _slate400, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              member.rol == 'MEMBER' ? '✓ Miembro' : 'Hacer Miembro',
                              style: const TextStyle(color: _slate100, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                    ],
                    PopupMenuItem(
                      value: 'KICK',
                      child: Row(
                        children: [
                          const Icon(Icons.gavel_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Expulsar',
                            style: TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'BAN',
                      child: Row(
                        children: [
                          const Icon(Icons.block_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Banear',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = ref.watch(userEmailProvider);
    final globalRole = ref.watch(userRoleProvider);
    final currentUserNodeRole = widget.nodo.rol?.toUpperCase() ?? 'MEMBER';
    final isGlobalAdmin = globalRole.toUpperCase() == 'ADMIN';
    final isCurrentUserOwner = currentUserNodeRole == 'OWNER' || isGlobalAdmin;
    final isOwnerOrAdmin = currentUserNodeRole == 'OWNER' || currentUserNodeRole == 'ADMIN' || isGlobalAdmin;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _navy900.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Nombre del nodo + botón cerrar
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _mint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hub_rounded, color: _mint, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nodo.nombre,
                            style: const TextStyle(
                              color: _slate100,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Token: IRL-${widget.nodo.tokenAcceso.length > 8 ? widget.nodo.tokenAcceso.substring(0, 8).toUpperCase() : widget.nodo.tokenAcceso.toUpperCase()}',
                            style: const TextStyle(
                              color: _slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _slate400),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Descripción
                if (widget.nodo.descripcion != null && widget.nodo.descripcion!.isNotEmpty) ...[
                  Text(
                    widget.nodo.descripcion!,
                    style: const TextStyle(color: _slate400, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                ],

                // Fila de Token y Copiar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _navy950,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.nodo.tokenAcceso,
                          style: const TextStyle(
                            color: _mint,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: _slate400, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copiar token de acceso completo',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.nodo.tokenAcceso));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Token de acceso copiado', style: TextStyle(color: Colors.white)),
                              backgroundColor: _mint.withValues(alpha: 0.85),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tab Selection / Lista de Participantes Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isOwnerOrAdmin) ...[
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _tabButton(0, 'Participantes (${_miembros?.length ?? widget.nodo.miembrosCount})'),
                              const SizedBox(width: 8),
                              _tabButton(1, 'Baneados (${_baneados?.length ?? 0})'),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: Text(
                          'PARTICIPANTES (${_miembros?.length ?? widget.nodo.miembrosCount})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                    if (_updating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _mint),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lista de Participantes body / Baneados body
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _navy950,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: _activeTab == 0
                        ? _buildMembersList(currentUserEmail, isCurrentUserOwner, currentUserNodeRole, isGlobalAdmin)
                        : _buildBaneadosList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Botones del Diálogo
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _slate400,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    if (isCurrentUserOwner) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Eliminar nodo', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          // Cerrar el detalles dialog y confirmar delete
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
