import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/subgrupos_repository.dart';
import '../../providers/subgrupos_provider.dart';
import '../../providers/chat_provider.dart';
import 'create_subgrupo_dialog.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _cyan = AppColors.cyan;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class SubgruposView extends ConsumerWidget {
  final String nodoId;
  final void Function(Subgrupo sub)? onOpenChat;

  const SubgruposView({
    super.key,
    required this.nodoId,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subgruposState = ref.watch(subgruposProvider(nodoId));

    if (subgruposState.isLoading && subgruposState.subgrupos.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }

    return Container(
      color: _navy950,
      child: Column(
        children: [
          // Sub-header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: _cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Subgrupos del Nodo (${subgruposState.subgrupos.length})',
                          style: const TextStyle(
                            color: _slate100,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Espacios temáticos y equipos de trabajo focalizados',
                      style: TextStyle(color: _slate500, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _navy950,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo Subgrupo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  onPressed: () => CreateSubgrupoDialog.show(context, nodoId),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),

          // Content
          Expanded(
            child: subgruposState.subgrupos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _navy900,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(Icons.group_work_outlined, color: _slate400, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay subgrupos creados todavía',
                          style: TextStyle(color: _slate100, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Organiza a tu equipo creando el primer subgrupo de trabajo.',
                          style: TextStyle(color: _slate500, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cyan,
                            foregroundColor: _navy950,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Crear Subgrupo', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => CreateSubgrupoDialog.show(context, nodoId),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: subgruposState.subgrupos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final sub = subgruposState.subgrupos[idx];
                      return _SubgrupoCard(
                        sub: sub,
                        nodoId: nodoId,
                        onOpenChat: onOpenChat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubgrupoCard extends ConsumerWidget {
  final Subgrupo sub;
  final String nodoId;
  final void Function(Subgrupo sub)? onOpenChat;

  const _SubgrupoCard({
    required this.sub,
    required this.nodoId,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void handleOpenChat() {
      if (onOpenChat != null) {
        onOpenChat!(sub);
      } else {
        ref.read(selectedSubgrupoProvider.notifier).state = sub;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: handleOpenChat,
        borderRadius: BorderRadius.circular(14),
        hoverColor: _cyan.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _navy900,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (sub.esPrivado ? _cyan : _mint).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sub.esPrivado ? Icons.lock_rounded : Icons.groups_rounded,
                  color: sub.esPrivado ? _cyan : _mint,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sub.nombre,
                            style: const TextStyle(
                              color: _slate100,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (sub.esPrivado ? _cyan : _mint).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sub.esPrivado ? 'Privado' : 'Público',
                            style: TextStyle(
                              color: sub.esPrivado ? _cyan : _mint,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sub.descripcion != null && sub.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sub.descripcion!,
                        style: const TextStyle(color: _slate400, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: _slate500, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${sub.miembrosCount} ${sub.miembrosCount == 1 ? "integrante" : "integrantes"}',
                          style: const TextStyle(color: _slate500, fontSize: 11),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.chat_bubble_outline_rounded, color: _cyan, size: 13),
                        const SizedBox(width: 4),
                        const Text(
                          'Chat disponible',
                          style: TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Abrir chat
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: _navy950,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                    label: const Text('Abrir Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: handleOpenChat,
                  ),
                  const SizedBox(width: 8),
                  // Unirse / Salir
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: sub.isMember ? const Color(0xFFEF4444) : _cyan,
                      ),
                      foregroundColor: sub.isMember ? const Color(0xFFEF4444) : _cyan,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(sub.isMember ? Icons.exit_to_app_rounded : Icons.login_rounded, size: 15),
                    label: Text(
                      sub.isMember ? 'Salir' : 'Unirse',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    onPressed: () {
                      ref.read(subgruposProvider(nodoId).notifier).toggleJoin(sub);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _slate500, size: 18),
                    tooltip: 'Eliminar subgrupo',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: _navy900,
                          title: const Text('¿Eliminar subgrupo?', style: TextStyle(color: _slate100, fontSize: 16)),
                          content: Text('Se eliminará "${sub.nombre}" de forma permanente.', style: const TextStyle(color: _slate400, fontSize: 13)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: _slate400))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(subgruposProvider(nodoId).notifier).deleteSubgrupo(sub.id);
                      }
                    },
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

