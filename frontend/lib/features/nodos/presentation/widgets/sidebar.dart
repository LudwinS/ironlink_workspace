import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/nodos_provider.dart';
import '../../../iam/providers/auth_provider.dart';

const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

const double _sidebarWidth = 220.0;

class Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String role;
  final bool isDrawer;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.role,
    this.isDrawer = false,
  });

  bool _canSeeConfig(String role) {
    return role.trim().toUpperCase() == 'ADMIN';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);
    final nodosState = ref.watch(nodosProvider);
    final selectedNodo = ref.watch(selectedNodoProvider);

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
          NavItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            isSelected: selectedIndex == 0 && selectedNodo == null,
            onTap: () => onSelect(0),
          ),
          NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Mis nodos',
            isSelected: selectedIndex == 1 && selectedNodo == null,
            onTap: () => onSelect(1),
          ),
          NavItem(
            icon: Icons.link_rounded,
            label: 'Unirse a nodo',
            isSelected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),

          const SizedBox(height: 16),

          // ── RED ────────────────────────────────────────────────────────
          _sectionLabel('RED'),
          NavItem(
            icon: Icons.shield_rounded,
            label: 'Túnel VPN',
            isSelected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),

          // ── Canales de Chat (Discord style) ──
          if (nodosState.nodos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionLabel('CANALES DE CHAT'),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: nodosState.nodos.length,
                itemBuilder: (context, idx) {
                  final nodo = nodosState.nodos[idx];
                  final isSelected = selectedNodo?.id == nodo.id;
                  return NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '# ${nodo.nombre}',
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(selectedNodoProvider.notifier).state = nodo;
                      onSelect(1);
                    },
                  );
                },
              ),
            ),
          ] else
            const Spacer(),

          // ── PERFIL ────────────────────────────────────────────────────
          _sectionLabel('PERFIL'),
          NavItem(
            icon: Icons.person_outline_rounded,
            label: username,
            isSelected: false,
            onTap: () {},
          ),
          if (_canSeeConfig(role))
            NavItem(
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

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
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
