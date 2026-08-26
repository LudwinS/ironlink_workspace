import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../data/nodos_repository.dart';
import '../../data/subgrupos_repository.dart';
import '../../providers/nodos_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/subgrupos_provider.dart';
import '../../../iam/providers/auth_provider.dart';
import 'nodo_details_dialog.dart';
import 'subgrupos_view.dart';
import 'reuniones_view.dart';
import 'assign_members_dialog.dart';
import 'edit_subgrupo_dialog.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;
const _slate600 = AppColors.slate600;

Color _getStatusColor(String? status) {
  if (status == null || status.isEmpty) return const Color(0xFF10B981);
  final lower = status.toLowerCase();
  if (status.contains('🔴') || lower.contains('ocupado') || lower.contains('no molestar')) {
    return const Color(0xFFEF4444);
  }
  if (status.contains('🟡') || lower.contains('reunión') || lower.contains('reunion') || lower.contains('ausente')) {
    return const Color(0xFFF59E0B);
  }
  if (status.contains('📚') || lower.contains('estudiando') || lower.contains('desarrollando')) {
    return const Color(0xFF00E5FF);
  }
  return const Color(0xFF10B981);
}

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
  List<SubgrupoMiembro> _subMiembros = [];
  Timer? _membersTimer;
  bool _showMembersSidebar = true;
  int _currentTab = 0; // 0: Chat, 1: Subgrupos, 2: Reuniones

  @override
  void initState() {
    super.initState();
    _fetchMiembros();
    _membersTimer = Timer.periodic(const Duration(seconds: 2), (_) {
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

      final currentSub = ref.read(selectedSubgrupoProvider);
      if (currentSub != null) {
        try {
          final subRepo = ref.read(subgruposRepositoryProvider);
          final subList = await subRepo.fetchSubgrupoMiembros(
            nodoId: widget.nodo.id,
            subgrupoId: currentSub.id,
          );
          if (mounted) {
            setState(() {
              _subMiembros = subList;
            });
          }
        } catch (_) {}
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

  Widget _workspaceTabBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = _mint,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeColor : _slate400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : _slate400,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesProvider);
    final selectedSubgrupo = ref.watch(selectedSubgrupoProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final currentUserEmail = ref.watch(userEmailProvider);
    final globalRole = ref.watch(userRoleProvider);
    final currentUserNodeRole = widget.nodo.rol?.toUpperCase() ?? 'MEMBER';
    final isGlobalAdmin = globalRole.toUpperCase() == 'ADMIN';
    final isOwnerOrGlobalAdmin = currentUserNodeRole == 'OWNER' || isGlobalAdmin;
    final subgruposState = ref.watch(subgruposProvider(widget.nodo.id));
    final totalSubgruposUnread = subgruposState.subgrupos.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );

    final isSubgrupoLocked = selectedSubgrupo != null &&
        selectedSubgrupo.esPrivado &&
        !selectedSubgrupo.isMember &&
        !isOwnerOrGlobalAdmin;

    final themeColor = selectedSubgrupo != null ? _cyan : _mint;

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
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: _navy900,
                    border: Border(bottom: BorderSide(color: _border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      if (selectedSubgrupo != null) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: _cyan, size: 20),
                          tooltip: 'Volver al Chat General',
                          onPressed: () {
                            ref.read(selectedSubgrupoProvider.notifier).state = null;
                            setState(() => _currentTab = 0);
                          },
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          selectedSubgrupo.esPrivado ? Icons.lock_rounded : Icons.groups_rounded,
                          color: _cyan,
                          size: 22,
                        ),
                      ] else ...[
                        const Text(
                          '#',
                          style: TextStyle(
                            color: _slate500,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    selectedSubgrupo != null
                                        ? selectedSubgrupo.nombre
                                        : widget.nodo.nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _slate100,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (selectedSubgrupo != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (selectedSubgrupo.esPrivado ? _cyan : _mint).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selectedSubgrupo.esPrivado ? 'Subgrupo Privado' : 'Subgrupo Público',
                                      style: TextStyle(
                                        color: selectedSubgrupo.esPrivado ? _cyan : _mint,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedSubgrupo != null
                                  ? (selectedSubgrupo.descripcion?.isNotEmpty == true
                                      ? selectedSubgrupo.descripcion!
                                      : '${selectedSubgrupo.miembrosCount} miembros en este subgrupo')
                                  : (widget.nodo.descripcion?.isNotEmpty == true
                                      ? widget.nodo.descripcion!
                                      : 'Canal general del nodo'),
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

                      // Tabs de selección
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _navy950,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botón Chat General
                                _workspaceTabBtn(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: 'Chat General',
                                  isSelected: _currentTab == 0 && selectedSubgrupo == null,
                                  activeColor: _mint,
                                  onTap: () {
                                    ref.read(selectedSubgrupoProvider.notifier).state = null;
                                    setState(() => _currentTab = 0);
                                  },
                                ),
                                // Si hay subgrupo activo, mostrar pestaña dedicada
                                if (selectedSubgrupo != null) ...[
                                  const SizedBox(width: 4),
                                  _workspaceTabBtn(
                                    icon: selectedSubgrupo.esPrivado ? Icons.lock_outline_rounded : Icons.forum_outlined,
                                    label: '#${selectedSubgrupo.nombre}',
                                    isSelected: _currentTab == 0,
                                    activeColor: _cyan,
                                    badgeCount: selectedSubgrupo.unreadCount,
                                    onTap: () => setState(() => _currentTab = 0),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                _workspaceTabBtn(
                                  icon: Icons.groups_rounded,
                                  label: 'Subgrupos',
                                  isSelected: _currentTab == 1,
                                  activeColor: _cyan,
                                  badgeCount: totalSubgruposUnread,
                                  onTap: () => setState(() => _currentTab = 1),
                                ),
                                const SizedBox(width: 4),
                                _workspaceTabBtn(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Reuniones',
                                  isSelected: _currentTab == 2,
                                  activeColor: _mint,
                                  onTap: () => setState(() => _currentTab = 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedSubgrupo != null) ...[
                        IconButton(
                          icon: const Icon(Icons.group_add_rounded, color: _cyan, size: 20),
                          tooltip: 'Asignar miembros a este subgrupo',
                          onPressed: () async {
                            await AssignMembersDialog.show(
                              context,
                              nodoId: widget.nodo.id,
                              subgrupo: selectedSubgrupo,
                            );
                            _fetchMiembros();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: _slate400, size: 19),
                          tooltip: 'Editar subgrupo en caliente',
                          onPressed: () async {
                            await EditSubgrupoDialog.show(
                              context,
                              nodoId: widget.nodo.id,
                              subgrupo: selectedSubgrupo,
                            );
                          },
                        ),
                      ],
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
                          color: _showMembersSidebar ? themeColor : _slate400,
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

                // Cuerpo condicional según Tab seleccionado
                if (_currentTab == 1)
                  Expanded(
                    child: SubgruposView(
                      nodoId: widget.nodo.id,
                      onOpenChat: (sub) {
                        ref.read(selectedSubgrupoProvider.notifier).state = sub;
                        setState(() => _currentTab = 0);
                        _fetchMiembros();
                      },
                    ),
                  )
                else if (_currentTab == 2)
                  Expanded(child: ReunionesView(nodoId: widget.nodo.id))
                else if (isSubgrupoLocked) ...[
                  // Pantalla de bloqueo si el subgrupo es privado y no es miembro
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _navy900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _cyan.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_person_rounded, color: _cyan, size: 48),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Subgrupo Privado: ${selectedSubgrupo.nombre}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _slate100,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              selectedSubgrupo.descripcion?.isNotEmpty == true
                                  ? selectedSubgrupo.descripcion!
                                  : 'Este subgrupo es privado. Para poder ver los mensajes y participar en las conversaciones, debes unirte al equipo.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _slate400, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cyan,
                                  foregroundColor: _navy950,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.login_rounded, size: 18),
                                label: const Text(
                                  'Unirse a este subgrupo',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                onPressed: () async {
                                  final success = await ref.read(subgruposProvider(widget.nodo.id).notifier).toggleJoin(selectedSubgrupo);
                                  if (success) {
                                    final updatedList = ref.read(subgruposProvider(widget.nodo.id)).subgrupos;
                                    final updatedSub = updatedList.firstWhere(
                                      (s) => s.id == selectedSubgrupo.id,
                                      orElse: () => selectedSubgrupo.copyWith(
                                        isMember: true,
                                        miembrosCount: selectedSubgrupo.miembrosCount + 1,
                                      ),
                                    );
                                    ref.read(selectedSubgrupoProvider.notifier).state = updatedSub;
                                    _fetchMiembros();
                                    _showSuccessSnack('¡Te has unido al subgrupo exitosamente!');
                                  } else {
                                    final err = ref.read(subgruposProvider(widget.nodo.id)).errorMessage ?? 'No se pudo unir al subgrupo.';
                                    _showErrorSnack(err);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: _slate400),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Volver al chat general'),
                              onPressed: () {
                                ref.read(selectedSubgrupoProvider.notifier).state = null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Banner informativo de Subgrupo Activo
                  if (selectedSubgrupo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _cyan.withValues(alpha: 0.08),
                        border: const Border(bottom: BorderSide(color: _border, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: _cyan, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estás en el canal de subgrupo #${selectedSubgrupo.nombre}. Los mensajes enviados aquí solo son visibles para los integrantes del subgrupo.',
                              style: const TextStyle(color: _cyan, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: _slate400,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ref.read(selectedSubgrupoProvider.notifier).state = null;
                            },
                            child: const Text('Ir al General', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),

                  // Lista de Mensajes
                  Expanded(
                    child: chatState.loading
                        ? Center(child: CircularProgressIndicator(color: themeColor))
                        : chatState.mensajes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      selectedSubgrupo != null ? Icons.groups_rounded : Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: _slate500.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      selectedSubgrupo != null
                                          ? '¡Bienvenido al subgrupo #${selectedSubgrupo.nombre}!'
                                          : '¡Aquí comienza la conversación!',
                                      style: const TextStyle(color: _slate400, fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedSubgrupo != null
                                          ? 'Comienza a compartir ideas y colaborar con tu equipo en este subgrupo.'
                                          : 'Envía un mensaje para saludar a todos.',
                                      style: const TextStyle(color: _slate600, fontSize: 12),
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
                                  final senderMember = _miembros.cast<NodoMiembro?>().firstWhere(
                                    (m) => m?.userId == msg.userId,
                                    orElse: () => null,
                                  );
                                  final isOwner = msg.userId == widget.nodo.creadorId;
                                  final role = isOwner
                                      ? 'OWNER'
                                      : (senderMember?.rol ?? (isSelf ? widget.nodo.rol : 'MEMBER'));

                                  return ChatMessageRow(
                                    mensaje: msg,
                                    isSelf: isSelf,
                                    userRole: role,
                                    accentColor: themeColor,
                                    senderAvatarUrl: senderMember?.avatarUrl ?? msg.avatarUrl,
                                    senderAvatarColor: senderMember?.avatarColor ?? msg.avatarColor,
                                    senderStatusText: senderMember?.statusText ?? msg.statusText,
                                  );
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
                            cursorColor: themeColor,
                            onFieldSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: selectedSubgrupo != null
                                  ? 'Enviar mensaje a #${selectedSubgrupo.nombre}'
                                  : 'Enviar mensaje a #${widget.nodo.nombre}',
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
                                borderSide: BorderSide(color: themeColor, width: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: themeColor,
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
                    selectedSubgrupo != null
                        ? 'MIEMBROS SUBGRUPO (${_subMiembros.isNotEmpty ? _subMiembros.length : selectedSubgrupo.miembrosCount})'
                        : 'INTEGRANTES (${_miembros.length})',
                    style: const TextStyle(
                      color: _slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: selectedSubgrupo != null && _subMiembros.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _subMiembros.length,
                          itemBuilder: (context, idx) {
                            final m = _subMiembros[idx];
                            final isSelf = m.email == currentUserEmail;
                            return SubgrupoMemberSidebarRow(member: m, isSelf: isSelf);
                          },
                        )
                      : _miembros.isEmpty
                          ? Center(child: CircularProgressIndicator(color: themeColor))
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

// ── Fila del Integrante del Subgrupo en el Panel Lateral ────────────────────

class SubgrupoMemberSidebarRow extends StatelessWidget {
  final SubgrupoMiembro member;
  final bool isSelf;

  const SubgrupoMemberSidebarRow({
    super.key,
    required this.member,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(member.statusText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: member.avatarUrl,
                  avatarColor: member.avatarColor,
                  name: member.name,
                  size: 32,
                  showBorder: isSelf,
                  borderColor: _cyan,
                ),
                // Indicador de presencia en vivo con color según estado
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _navy900, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelf ? '${member.name} (Tú)' : member.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelf ? _cyan : _slate100,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    member.statusText?.isNotEmpty == true ? member.statusText! : '● En línea',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de Mensaje del Chat ────────────────────────────────────────────────

class ChatMessageRow extends StatelessWidget {
  final Mensaje mensaje;
  final bool isSelf;
  final String? userRole;
  final Color accentColor;
  final String? senderAvatarUrl;
  final String? senderAvatarColor;
  final String? senderStatusText;

  const ChatMessageRow({
    super.key,
    required this.mensaje,
    required this.isSelf,
    this.userRole,
    this.accentColor = _mint,
    this.senderAvatarUrl,
    this.senderAvatarColor,
    this.senderStatusText,
  });

  Widget _buildRoleTag(String role) {
    Color color;
    Color bg;
    String label;
    switch (role.toUpperCase()) {
      case 'OWNER':
        color = const Color(0xFFF59E0B); // Gold / Amber
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        label = 'CREADOR';
        break;
      case 'ADMIN':
        color = _cyan;
        bg = _cyan.withValues(alpha: 0.18);
        label = 'ADMIN';
        break;
      default:
        color = _slate400;
        bg = _slate400.withValues(alpha: 0.12);
        label = 'MIEMBRO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = senderStatusText ?? mensaje.statusText;
    final statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar con soporte para Foto Personalizada / Color Base
          UserAvatar(
            avatarUrl: senderAvatarUrl ?? mensaje.avatarUrl,
            avatarColor: senderAvatarColor ?? mensaje.avatarColor,
            name: mensaje.userName,
            size: 40,
            showBorder: isSelf,
            borderColor: accentColor,
          ),
          const SizedBox(width: 12),
          // Contenido del mensaje
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      mensaje.userName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelf ? accentColor : _slate100,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (userRole != null && userRole!.isNotEmpty)
                      _buildRoleTag(userRole!),
                    if (status != null && status.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Text(
                          status.trim(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
    final statusColor = _getStatusColor(member.statusText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Avatar con Indicador de Presencia en vivo y Foto personalizada
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: member.avatarUrl,
                  avatarColor: member.avatarColor,
                  name: member.name,
                  size: 32,
                  showBorder: isSelf,
                  borderColor: _mint,
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _navy900, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Name y Presencia
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelf ? '${member.name} (Tú)' : member.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelf ? _mint : _slate100,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    member.statusText?.isNotEmpty == true ? member.statusText! : '● En línea',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

