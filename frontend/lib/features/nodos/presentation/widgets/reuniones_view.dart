import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reuniones_repository.dart';
import '../../providers/reuniones_provider.dart';
import 'create_reunion_dialog.dart';

const _navy950 = AppColors.navy950;
const _navy900 = AppColors.navy900;
const _border = AppColors.border;
const _mint = AppColors.mint;
const _slate100 = AppColors.slate100;
const _slate400 = AppColors.slate400;
const _slate500 = AppColors.slate500;

class ReunionesView extends ConsumerWidget {
  final String nodoId;
  const ReunionesView({super.key, required this.nodoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reunionesState = ref.watch(reunionesProvider(nodoId));

    if (reunionesState.isLoading && reunionesState.reuniones.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _mint));
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.video_call_rounded, color: _mint, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Reuniones y Sesiones de Nodo (${reunionesState.reuniones.length})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _slate100,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Videollamadas programadas, clases y revisiones de sprint',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _slate500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: _navy950,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Programar Sesión', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  onPressed: () => CreateReunionDialog.show(context, nodoId),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),

          // Content
          Expanded(
            child: reunionesState.reuniones.isEmpty
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
                          child: const Icon(Icons.event_available_outlined, color: _slate400, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay reuniones programadas',
                          style: TextStyle(color: _slate100, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Programa una sesión síncrona o clase para colaborar con el equipo.',
                          style: TextStyle(color: _slate500, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mint,
                            foregroundColor: _navy950,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.video_call, size: 16),
                          label: const Text('Programar Primera Reunión', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => CreateReunionDialog.show(context, nodoId),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: reunionesState.reuniones.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final reunion = reunionesState.reuniones[idx];
                      return _ReunionCard(reunion: reunion, nodoId: nodoId);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReunionCard extends ConsumerWidget {
  final Reunion reunion;
  final String nodoId;
  const _ReunionCard({required this.reunion, required this.nodoId});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpcoming = reunion.fechaInicio.isAfter(DateTime.now());

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date icon block
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _navy950,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Text(
                  reunion.fechaInicio.day.toString(),
                  style: const TextStyle(
                    color: _mint,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _monthName(reunion.fechaInicio.month),
                  style: const TextStyle(
                    color: _slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Main details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reunion.titulo,
                      style: const TextStyle(
                        color: _slate100,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isUpcoming ? _mint : _slate500).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUpcoming ? '● Programada' : 'Finalizada',
                        style: TextStyle(
                          color: isUpcoming ? _mint : _slate400,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reunion.descripcion != null && reunion.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reunion.descripcion!,
                    style: const TextStyle(color: _slate400, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _slate500, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(reunion.fechaInicio),
                      style: const TextStyle(color: _slate400, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_pin_circle_outlined, color: _slate500, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Por ${reunion.creadorNombre}',
                      style: const TextStyle(color: _slate500, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reunion.enlaceReunion != null && reunion.enlaceReunion!.isNotEmpty) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: _navy950,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text('Unirse a Meet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abriendo enlace: ${reunion.enlaceReunion}'),
                        backgroundColor: const Color(0xFF00BFA5),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: _slate500, size: 18),
                tooltip: 'Cancelar reunión',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _navy900,
                      title: const Text('¿Cancelar reunión?', style: TextStyle(color: _slate100, fontSize: 16)),
                      content: Text('Se cancelará "${reunion.titulo}".', style: const TextStyle(color: _slate400, fontSize: 13)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver', style: TextStyle(color: _slate400))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Cancelar Sesión', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(reunionesProvider(nodoId).notifier).deleteReunion(reunion.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return months[month - 1];
  }
}
