import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_vault.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/nodos_provider.dart';
import '../data/nodos_repository.dart';
import '../../iam/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta de colores oficial IronLink
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Constantes de layout
// ─────────────────────────────────────────────────────────────────────────────

const double _sidebarWidth = 220.0;
const double _mobileBreakpoint = 768.0;

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades RBAC
// ─────────────────────────────────────────────────────────────────────────────

/// Normaliza el rol para comparación segura.
String _normalizeRole(String role) => role.trim().toUpperCase();

bool _canCreateNodo(String role) {
  return true;
}

bool _canSeeConfig(String role) {
  final r = _normalizeRole(role);
  return r == 'ADMIN';
}

// ═════════════════════════════════════════════════════════════════════════════
// DashboardScreen — Pantalla principal
// ═════════════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Carga inicial de nodos al entrar al dashboard
    Future.microtask(() => ref.read(nodosProvider.notifier).loadNodos());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: _navy950,
      drawer: isMobile ? _buildDrawer(role) : null,
      body: Row(
        children: [
          // Sidebar fijo en desktop
          if (!isMobile) _Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: _handleNavSelect,
            role: role,
          ),
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                _TopBar(isMobile: isMobile),
                Expanded(
                  child: _MainContent(role: role),
                ),
              ],
            ),
          ),
        ],
      ),
      // FAB para crear nodo (solo si tiene permisos)
      floatingActionButton: _canCreateNodo(role)
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateNodoDialog(context),
              backgroundColor: _mint,
              foregroundColor: _navy950,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Crear nodo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawer(String role) {
    return Drawer(
      backgroundColor: _navy900,
      child: _Sidebar(
        selectedIndex: _selectedIndex,
        onSelect: (i) {
          _handleNavSelect(i);
          Navigator.pop(context); // cierra el drawer
        },
        role: role,
        isDrawer: true,
      ),
    );
  }

  void _handleNavSelect(int index) {
    setState(() => _selectedIndex = index);
    // Index 2 = Unirse a nodo
    if (index == 2) {
      _showJoinNodoDialog(context);
    }
  }

  void _showCreateNodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CreateNodoDialog(),
    );
  }

  void _showJoinNodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _JoinNodoDialog(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _TopBar — Barra superior con avatar y notificaciones
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends ConsumerWidget {
  final bool isMobile;
  const _TopBar({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);
    final initials = _getInitials(username);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _navy950,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: _slate100),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          // VPN status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _darkMint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _darkMint, width: 1),
            ),
            child: Row(
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
                const Text(
                  'VPN · IRONLINK-NODE-01',
                  style: TextStyle(
                    color: _mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Campana de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: _slate400, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_mint, _cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: _navy950,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
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
}

// ═════════════════════════════════════════════════════════════════════════════
// _Sidebar — Navegación lateral
// ═════════════════════════════════════════════════════════════════════════════

class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String role;
  final bool isDrawer;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.role,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);

    return Container(
      width: isDrawer ? null : _sidebarWidth,
      decoration: const BoxDecoration(
        color: _navy900,
        border: Border(right: BorderSide(color: _border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.hub_rounded,
                    color: _mint,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'IronLink',
                  style: TextStyle(
                    color: _slate100,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── NAVEGACIÓN ────────────────────────────────────────────────
          _sectionLabel('NAVEGACIÓN'),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            isSelected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Mis nodos',
            isSelected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.link_rounded,
            label: 'Unirse a nodo',
            isSelected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),

          const SizedBox(height: 16),

          // ── RED ────────────────────────────────────────────────────────
          _sectionLabel('RED'),
          _NavItem(
            icon: Icons.shield_rounded,
            label: 'Túnel VPN',
            isSelected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),

          const Spacer(),

          // ── PERFIL ────────────────────────────────────────────────────
          _sectionLabel('PERFIL'),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: username,
            isSelected: false,
            onTap: () {},
          ),
          if (_canSeeConfig(role))
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Configuración',
              isSelected: selectedIndex == 4,
              onTap: () => onSelect(4),
            ),

          // ── Cerrar sesión ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _slate500,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Ítem de navegación del sidebar ──────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? _mint.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: _border.withValues(alpha: 0.3),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? _mint : _slate400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? _mint : _slate400,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
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

// ═════════════════════════════════════════════════════════════════════════════
// _MainContent — Área de contenido principal
// ═════════════════════════════════════════════════════════════════════════════

class _MainContent extends ConsumerWidget {
  final String role;
  const _MainContent({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodosState = ref.watch(nodosProvider);

    // Listener para mostrar snackbars de éxito/error
    ref.listen<NodosState>(nodosProvider, (prev, next) {
      if (next.successMessage != null) {
        _showSnack(context, next.successMessage!, _mint);
        ref.read(nodosProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        _showSnack(context, next.errorMessage!, const Color(0xFFEF4444));
        ref.read(nodosProvider.notifier).clearMessages();
      }
    });

    return RefreshIndicator(
      color: _mint,
      backgroundColor: _navy900,
      onRefresh: () => ref.read(nodosProvider.notifier).loadNodos(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
        children: [
          // ── Nodo activo banner ────────────────────────────────────────
          if (nodosState.nodoActivo != null)
            _NodoActivoBanner(nodo: nodosState.nodoActivo!),

          if (nodosState.nodoActivo != null) const SizedBox(height: 28),

          // ── Sección: MIS NODOS ───────────────────────────────────────
          const Text(
            'MIS NODOS',
            style: TextStyle(
              color: _slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // ── Contenido según estado ───────────────────────────────────
          _buildNodosContent(context, nodosState, role),
        ],
      ),
    );
  }

  Widget _buildNodosContent(
      BuildContext context, NodosState state, String role) {
    if (state.status == NodosStatus.loading && state.nodos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    if (state.nodos.isEmpty) {
      return _EmptyNodosState(canCreate: _canCreateNodo(role));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.65,
          ),
          itemCount: state.nodos.length,
          itemBuilder: (context, i) => _NodoCard(nodo: state.nodos[i]),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _NodoActivoBanner — Banner del nodo activo (estilo "CLASE ACTIVA HOY")
// ═════════════════════════════════════════════════════════════════════════════

class _NodoActivoBanner extends StatelessWidget {
  final Nodo nodo;
  const _NodoActivoBanner({required this.nodo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NODO ACTIVO',
          style: TextStyle(
            color: _mint,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _darkMint.withValues(alpha: 0.35),
                _navy900,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _darkMint, width: 1),
          ),
          child: Row(
            children: [
              // Ícono del nodo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _darkMint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_rounded, color: _mint, size: 22),
              ),
              const SizedBox(width: 16),
              // Info del nodo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodo.nombre,
                      style: const TextStyle(
                        color: _slate100,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (nodo.creadorNombre != null) nodo.creadorNombre!,
                        '${nodo.miembrosCount} conectados',
                      ].join(' · '),
                      style: const TextStyle(color: _slate400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Botón unirse
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy950,
                  backgroundColor: _mint,
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text(
                  'Unirse →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _NodoCard — Tarjeta individual de nodo
// ═════════════════════════════════════════════════════════════════════════════

class _NodoCard extends ConsumerWidget {
  final Nodo nodo;
  const _NodoCard({required this.nodo});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
          '¿Estás seguro de que deseas eliminar el nodo "${nodo.nombre}"? Esta acción no se puede deshacer y desconectará a todos los miembros.',
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
              await ref.read(nodosProvider.notifier).deleteNodo(nodo.id);
            },
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = nodo.isActive ? _mint : _slate500;
    final statusLabel = nodo.isActive ? 'Activo' : 'Inactivo';
    final globalRole = ref.watch(userRoleProvider);
    final canDelete = nodo.rol == 'OWNER' || globalRole == 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: indicador de estado + badge
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: nodo.isActive
                      ? [
                          BoxShadow(
                            color: _mint.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nombre del nodo
          Text(
            nodo.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _slate100,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          // Token (abreviado) + Creador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  [
                    'IRL-${nodo.tokenAcceso.length > 8 ? nodo.tokenAcceso.substring(0, 8).toUpperCase() : nodo.tokenAcceso.toUpperCase()}',
                    if (nodo.creadorNombre != null) nodo.creadorNombre!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _slate600, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14, color: _slate500),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copiar token de acceso',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: nodo.tokenAcceso));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Token de acceso copiado al portapapeles', style: TextStyle(color: Colors.white)),
                      backgroundColor: _mint.withValues(alpha: 0.85),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          const Spacer(),

          // Fila inferior: miembros y botón eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 15, color: _slate500),
                  const SizedBox(width: 6),
                  Text(
                    '${nodo.miembrosCount} miembros',
                    style:
                        const TextStyle(color: _slate500, fontSize: 12),
                  ),
                ],
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Color(0xFFEF4444)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar nodo',
                  onPressed: () => _confirmDelete(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _EmptyNodosState — Estado vacío
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyNodosState extends StatelessWidget {
  final bool canCreate;
  const _EmptyNodosState({required this.canCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 72,
              color: _slate500.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin nodos todavía',
              style: TextStyle(
                color: _slate400,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canCreate
                  ? 'Crea tu primer nodo o únete a uno existente.'
                  : 'Únete a un nodo usando un token de acceso.',
              style: const TextStyle(color: _slate500, fontSize: 13),
            ),
            if (canCreate) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  foregroundColor: _navy950,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Crear nodo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _CreateNodoDialog(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _CreateNodoDialog — Diálogo para crear un nodo
// ═════════════════════════════════════════════════════════════════════════════

class _CreateNodoDialog extends ConsumerStatefulWidget {
  const _CreateNodoDialog();

  @override
  ConsumerState<_CreateNodoDialog> createState() => _CreateNodoDialogState();
}

class _CreateNodoDialogState extends ConsumerState<_CreateNodoDialog> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
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
                        color: _mint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: _mint, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Crear nuevo nodo',
                      style: TextStyle(
                        color: _slate100,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo: Nombre
                _DialogTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre del nodo',
                  hint: 'Ej: Red de desarrollo',
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Campo: Descripción
                _DialogTextField(
                  controller: _descCtrl,
                  label: 'Descripción (opcional)',
                  hint: 'Una breve descripción del nodo...',
                  maxLines: 3,
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
                        backgroundColor: _mint,
                        foregroundColor: _navy950,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor:
                            _mint.withValues(alpha: 0.4),
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
                              'Crear nodo',
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
    );
  }

  Future<void> _onSubmit() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _submitting = true);
    final success = await ref.read(nodosProvider.notifier).createNodo(
          nombre: nombre,
          descripcion: _descCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (success) Navigator.pop(context);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _JoinNodoDialog — Diálogo para unirse a un nodo
// ═════════════════════════════════════════════════════════════════════════════

class _JoinNodoDialog extends ConsumerStatefulWidget {
  const _JoinNodoDialog();

  @override
  ConsumerState<_JoinNodoDialog> createState() => _JoinNodoDialogState();
}

class _JoinNodoDialogState extends ConsumerState<_JoinNodoDialog> {
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
                _DialogTextField(
                  controller: _tokenCtrl,
                  label: 'Token de acceso',
                  hint: 'Ej: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
                  autofocus: true,
                  maxLength: 64,
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
    );
  }

  Future<void> _onSubmit() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() => _submitting = true);
    final success = await ref.read(nodosProvider.notifier).joinNodo(token);
    if (mounted) {
      setState(() => _submitting = false);
      if (success) Navigator.pop(context);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _DialogTextField — Campo de texto reutilizable para diálogos
// ═════════════════════════════════════════════════════════════════════════════

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _slate400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: _slate100, fontSize: 14),
          cursorColor: _mint,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _slate500.withValues(alpha: 0.7)),
            filled: true,
            fillColor: _navy950,
            counterStyle: const TextStyle(color: _slate500, fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: _mint, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
