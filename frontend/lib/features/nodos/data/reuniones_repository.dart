import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Reunion {
  final String id;
  final String nodoId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? enlaceReunion;
  final String creadoPor;
  final String creadorNombre;
  final DateTime createdAt;

  const Reunion({
    required this.id,
    required this.nodoId,
    required this.titulo,
    this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    this.enlaceReunion,
    required this.creadoPor,
    required this.creadorNombre,
    required this.createdAt,
  });

  factory Reunion.fromJson(Map<String, dynamic> json) {
    return Reunion(
      id: json['id'] as String? ?? '',
      nodoId: json['nodo_id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.tryParse(json['fecha_inicio'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.tryParse(json['fecha_fin'].toString())
          : null,
      enlaceReunion: json['enlace_reunion'] as String?,
      creadoPor: json['creado_por'] as String? ?? '',
      creadorNombre: json['creador_nombre'] as String? ?? 'Usuario',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReunionesRepository {
  final Dio _client = ApiClient.instance;

  Future<List<Reunion>> fetchReuniones(String nodoId) async {
    try {
      final response = await _client.get('/nodos/$nodoId/reuniones');
      final data = response.data as Map<String, dynamic>;
      final list = (data['reuniones'] as List<dynamic>?) ?? [];
      return list.map((e) => Reunion.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al cargar reuniones';
      throw Exception(msg);
    }
  }

  Future<Reunion> createReunion({
    required String nodoId,
    required String titulo,
    String? descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? enlaceReunion,
  }) async {
    try {
      final response = await _client.post(
        '/nodos/$nodoId/reuniones',
        data: {
          'titulo': titulo,
          if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
          'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
          if (fechaFin != null) 'fecha_fin': fechaFin.toUtc().toIso8601String(),
          if (enlaceReunion != null && enlaceReunion.isNotEmpty) 'enlace_reunion': enlaceReunion,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['reunion'] != null) {
        return Reunion.fromJson(data['reunion'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Error al programar reunión');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al programar reunión';
      throw Exception(msg);
    }
  }

  Future<void> deleteReunion({
    required String nodoId,
    required String reunionId,
  }) async {
    try {
      await _client.delete('/nodos/$nodoId/reuniones/$reunionId');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al cancelar reunión';
      throw Exception(msg);
    }
  }
}

final reunionesRepositoryProvider = Provider<ReunionesRepository>((ref) {
  return ReunionesRepository();
});
