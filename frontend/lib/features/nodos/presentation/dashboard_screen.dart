import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/nodos_provider.dart';
import '../data/nodos_repository.dart';

// Import newly extracted widgets
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/nodo_card.dart';
import 'widgets/nodo_chat_workspace.dart';
import 'widgets/create_nodo_dialog.dart';
import 'widgets/join_nodo_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta de colores oficial IronLink
// ─────────────────────────────────────────────────────────────────────────────

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _mint = AppColors.mint;
const _darkMint = AppColors.darkMint;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

// ─────────────────────────────────────────────────────────────────────────────
// Constantes de layout
// ─────────────────────────────────────────────────────────────────────────────

const double _mobileBreakpoint = 768.0;

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades RBAC
// ─────────────────────────────────────────────────────────────────────────────

bool _canCreateNodo(String role) {
  return true;
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
    // Carga inicial de nodos al entrar al dashboard y arranque del polling
    Future.microtask(() {
      ref.read(nodosProvider.notifier).loadNodos();
      ref.read(nodosProvider.notifier).startPolling();
    });
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
          if (!isMobile) Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: _handleNavSelect,
            role: role,
          ),
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                TopBar(isMobile: isMobile),
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
      child: Sidebar(
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
    if (index != 1) {
      ref.read(selectedNodoProvider.notifier).state = null;
    }
    // Index 2 = Unirse a nodo
    if (index == 2) {
      _showJoinNodoDialog(context);
    }
  }

  void _showCreateNodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateNodoDialog(),
    );
  }

  void _showJoinNodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const JoinNodoDialog(),
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
    final selectedNodo = ref.watch(selectedNodoProvider);

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

    if (selectedNodo != null) {
      return NodoChatWorkspace(nodo: selectedNodo);
    }

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
          itemBuilder: (context, i) => NodoCard(nodo: state.nodos[i]),
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
                  builder: (_) => const CreateNodoDialog(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
