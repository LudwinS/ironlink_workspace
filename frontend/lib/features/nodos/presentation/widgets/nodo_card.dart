import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/nodos_repository.dart';
import '../../providers/nodos_provider.dart';

const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _slate100 = AppColors.slate100;
const _slate500 = AppColors.slate500;
const _slate600 = AppColors.slate600;

class NodoCard extends ConsumerWidget {
  final Nodo nodo;
  const NodoCard({super.key, required this.nodo});

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
          style: const TextStyle(color: _slate500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _slate500)),
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

  void _confirmLeave(BuildContext context, WidgetRef ref) {
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
            Text('¿Salir del nodo?', style: TextStyle(color: _slate100, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir del nodo "${nodo.nombre}"? Perderás acceso a su canal de comunicación.',
          style: const TextStyle(color: _slate500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(nodosProvider.notifier).leaveNodo(nodo.id);
            },
            child: const Text('Salir', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final canLeave = nodo.rol != 'OWNER';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedNodoProvider.notifier).state = nodo;
        },
        child: Container(
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
                    )
                  else if (canLeave)
                    IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Salir del nodo',
                      onPressed: () => _confirmLeave(context, ref),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
