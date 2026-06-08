import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/nodos_repository.dart';
import '../../providers/nodos_provider.dart';
import '../../providers/chat_provider.dart';
import '../../../iam/providers/auth_provider.dart';
import 'nodo_details_dialog.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;
const _slate600 = AppColors.slate600;

const double _mobileBreakpoint = 768.0;

class NodoChatWorkspace extends ConsumerStatefulWidget {
  final Nodo nodo;
  const NodoChatWorkspace({super.key, required this.nodo});

  @override
  ConsumerState<NodoChatWorkspace> createState() => _NodoChatWorkspaceState();
}

class _NodoChatWorkspaceState extends ConsumerState<NodoChatWorkspace> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<NodoMiembro> _miembros = [];
  Timer? _membersTimer;
  bool _showMembersSidebar = true;

  @override
  void initState() {
    super.initState();
    _fetchMiembros();
    _membersTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMiembros();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _membersTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMiembros() async {
    try {
      final repo = ref.read(nodosRepositoryProvider);
      final list = await repo.fetchMiembros(widget.nodo.id);
      if (mounted) {
        setState(() {
          _miembros = list;
        });
      }
    } catch (_) {
      // Silencioso
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final success = await ref.read(chatMessagesProvider.notifier).sendMensaje(text);
    if (success) {
      Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
    }
  }

  Future<void> _changeRole(String targetUserId, String newRol) async {
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.updateMiembroRol(
        nodoId: widget.nodo.id,
        userId: targetUserId,
        newRol: newRol,
      );
      _fetchMiembros();
    } catch (e) {
      _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _kickMember(String targetUserId, String name) async {
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.kickMiembro(widget.nodo.id, targetUserId);
      _fetchMiembros();
      _showSuccessSnack('Usuario $name expulsado');
    } catch (e) {
      _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _banMember(String targetUserId, String name) async {
    try {
      final repo = ref.read(nodosRepositoryProvider);
      await repo.banMiembro(widget.nodo.id, targetUserId);
      _fetchMiembros();
      _showSuccessSnack('Usuario $name baneado');
    } catch (e) {
      _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _mint.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final currentUserEmail = ref.watch(userEmailProvider);
    final globalRole = ref.watch(userRoleProvider);
    final currentUserNodeRole = widget.nodo.rol?.toUpperCase() ?? 'MEMBER';
    final isGlobalAdmin = globalRole.toUpperCase() == 'ADMIN';
    final isOwnerOrGlobalAdmin = currentUserNodeRole == 'OWNER' || isGlobalAdmin;

    // Auto scroll al cargar mensajes o recibir nuevos
    ref.listen<ChatMessagesState>(chatMessagesProvider, (prev, next) {
      if (prev == null || next.mensajes.length > prev.mensajes.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Row(
      children: [
        // Área central de chat
        Expanded(
          child: Container(
            color: _navy950,
            child: Column(
              children: [
                // Cabecera del chat
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: _navy900,
                    border: Border(bottom: BorderSide(color: _border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '#',
                        style: TextStyle(
                          color: _slate500,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nodo.nombre,
                              style: const TextStyle(
                                color: _slate100,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.nodo.descripcion != null && widget.nodo.descripcion!.isNotEmpty)
                              Text(
                                widget.nodo.descripcion!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _slate500,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: _slate400, size: 20),
                        tooltip: 'Configuración del nodo',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => NodoDetailsDialog(nodo: widget.nodo),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _showMembersSidebar ? Icons.group_rounded : Icons.group_outlined,
                          color: _showMembersSidebar ? _mint : _slate400,
                          size: 20,
                        ),
                        tooltip: 'Mostrar/Ocultar miembros',
                        onPressed: () {
                          setState(() {
                            _showMembersSidebar = !_showMembersSidebar;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Lista de Mensajes
                Expanded(
                  child: chatState.loading
                      ? const Center(child: CircularProgressIndicator(color: _mint))
                      : chatState.mensajes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _slate500.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '¡Aquí comienza la conversación!',
                                    style: TextStyle(color: _slate400, fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Envía un mensaje para saludar a todos.',
                                    style: TextStyle(color: _slate600, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: chatState.mensajes.length,
                              itemBuilder: (context, i) {
                                final msg = chatState.mensajes[i];
                                final isSelf = msg.userId == ref.watch(authProvider).userId;
                                return ChatMessageRow(mensaje: msg, isSelf: isSelf);
                              },
                            ),
                ),

                // Entrada de texto inferior
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: _navy900,
                    border: Border(top: BorderSide(color: _border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _msgCtrl,
                          style: const TextStyle(color: _slate100, fontSize: 14),
                          cursorColor: _mint,
                          onFieldSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Enviar mensaje a #${widget.nodo.nombre}',
                            hintStyle: TextStyle(color: _slate500.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: _navy950,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: _mint, width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _mint,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: _navy950, size: 18),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lateral derecho de Miembros estilo Discord
        if (_showMembersSidebar && (!isMobile || _showMembersSidebar))
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: _navy900,
              border: Border(left: BorderSide(color: _border, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'INTEGRANTES (${_miembros.length})',
                    style: const TextStyle(
                      color: _slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: _miembros.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: _mint))
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            // Propietarios
                            if (_miembros.any((m) => m.rol.toUpperCase() == 'OWNER')) ...[
                              _categoryHeader('PROPIETARIO'),
                              ..._miembros
                                  .where((m) => m.rol.toUpperCase() == 'OWNER')
                                  .map((m) => _buildMemberRow(m, currentUserEmail, isGlobalAdmin, currentUserNodeRole, isOwnerOrGlobalAdmin)),
                            ],
                            // Administradores
                            if (_miembros.any((m) => m.rol.toUpperCase() == 'ADMIN')) ...[
                              _categoryHeader('ADMINISTRADORES'),
                              ..._miembros
                                  .where((m) => m.rol.toUpperCase() == 'ADMIN')
                                  .map((m) => _buildMemberRow(m, currentUserEmail, isGlobalAdmin, currentUserNodeRole, isOwnerOrGlobalAdmin)),
                            ],
                            // Miembros normales
                            if (_miembros.any((m) => m.rol.toUpperCase() == 'MEMBER')) ...[
                              _categoryHeader('MIEMBROS'),
                              ..._miembros
                                  .where((m) => m.rol.toUpperCase() == 'MEMBER')
                                  .map((m) => _buildMemberRow(m, currentUserEmail, isGlobalAdmin, currentUserNodeRole, isOwnerOrGlobalAdmin)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _categoryHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _slate600,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMemberRow(NodoMiembro m, String currentUserEmail, bool isGlobalAdmin, String currentUserNodeRole, bool isOwnerOrGlobalAdmin) {
    final isSelf = m.email == currentUserEmail;
    
    // Check if current user can manage this specific member
    bool canManage = false;
    if (!isSelf) {
      if (isGlobalAdmin || currentUserNodeRole == 'OWNER') {
        canManage = true;
      } else if (currentUserNodeRole == 'ADMIN') {
        canManage = m.rol.toUpperCase() == 'MEMBER';
      }
    }

    return MemberSidebarRow(
      member: m,
      isSelf: isSelf,
      canManage: canManage,
      onKick: () => _kickMember(m.userId, m.name),
      onBan: () => _banMember(m.userId, m.name),
      onChangeRole: (newRol) => _changeRole(m.userId, newRol),
    );
  }
}

// ── Fila de Mensaje del Chat ────────────────────────────────────────────────

class ChatMessageRow extends StatelessWidget {
  final Mensaje mensaje;
  final bool isSelf;

  const ChatMessageRow({
    super.key,
    required this.mensaje,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(mensaje.userName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelf
                  ? const LinearGradient(
                      colors: [_mint, _cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [_slate500, _slate600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(color: _border, width: 1),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: isSelf ? _navy950 : _slate100,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido del mensaje
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mensaje.userName,
                      style: TextStyle(
                        color: isSelf ? _mint : _slate100,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(mensaje.createdAt),
                      style: const TextStyle(
                        color: _slate500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mensaje.contenido,
                  style: const TextStyle(
                    color: _slate100,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ── Fila del Integrante en el Panel Lateral ─────────────────────────────────

class MemberSidebarRow extends StatelessWidget {
  final NodoMiembro member;
  final bool isSelf;
  final bool canManage;
  final VoidCallback? onKick;
  final VoidCallback? onBan;
  final Function(String)? onChangeRole;

  const MemberSidebarRow({
    super.key,
    required this.member,
    required this.isSelf,
    required this.canManage,
    this.onKick,
    this.onBan,
    this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelf
                    ? const LinearGradient(colors: [_mint, _cyan])
                    : const LinearGradient(colors: [_slate500, _slate600]),
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
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(
                isSelf ? '${member.name} (Tú)' : member.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelf ? _mint : _slate100,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Options if canManage
            if (canManage)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: _slate500, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: _navy900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: _border),
                ),
                onSelected: (action) {
                  if (action == 'KICK' && onKick != null) {
                    onKick!();
                  } else if (action == 'BAN' && onBan != null) {
                    onBan!();
                  } else if (action == 'ADMIN' && onChangeRole != null) {
                    onChangeRole!('ADMIN');
                  } else if (action == 'MEMBER' && onChangeRole != null) {
                    onChangeRole!('MEMBER');
                  }
                },
                itemBuilder: (ctx) => [
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
                  PopupMenuItem(
                    value: 'KICK',
                    child: Row(
                      children: [
                        const Icon(Icons.gavel_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        const Text('Expulsar', style: TextStyle(color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'BAN',
                    child: Row(
                      children: [
                        const Icon(Icons.block_rounded, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        const Text('Banear', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
