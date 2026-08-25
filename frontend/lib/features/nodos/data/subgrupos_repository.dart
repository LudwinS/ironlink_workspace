import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Subgrupo {
  final String id;
  final String nodoId;
  final String nombre;
  final String? descripcion;
  final bool esPrivado;
  final String creadoPor;
  final DateTime createdAt;
  final int miembrosCount;
  final bool isMember;

  const Subgrupo({
    required this.id,
    required this.nodoId,
    required this.nombre,
    this.descripcion,
    required this.esPrivado,
    required this.creadoPor,
    required this.createdAt,
    required this.miembrosCount,
    required this.isMember,
  });

  factory Subgrupo.fromJson(Map<String, dynamic> json) {
    return Subgrupo(
      id: json['id'] as String? ?? '',
      nodoId: json['nodo_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      esPrivado: json['es_privado'] as bool? ?? false,
      creadoPor: json['creado_por'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      miembrosCount: json['miembros_count'] as int? ?? (json['miembros_count'] is num ? (json['miembros_count'] as num).toInt() : 1),
      isMember: json['is_member'] as bool? ?? false,
    );
  }

  Subgrupo copyWith({
    String? id,
    String? nodoId,
    String? nombre,
    String? descripcion,
    bool? esPrivado,
    String? creadoPor,
    DateTime? createdAt,
    int? miembrosCount,
    bool? isMember,
  }) {
    return Subgrupo(
      id: id ?? this.id,
      nodoId: nodoId ?? this.nodoId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      esPrivado: esPrivado ?? this.esPrivado,
      creadoPor: creadoPor ?? this.creadoPor,
      createdAt: createdAt ?? this.createdAt,
      miembrosCount: miembrosCount ?? this.miembrosCount,
      isMember: isMember ?? this.isMember,
    );
  }
}

class SubgruposRepository {
  final Dio _client = ApiClient.instance;

  Future<List<Subgrupo>> fetchSubgrupos(String nodoId) async {
    try {
      final response = await _client.get('/nodos/$nodoId/subgrupos');
      final data = response.data as Map<String, dynamic>;
      final list = (data['subgrupos'] as List<dynamic>?) ?? [];
      return list.map((e) => Subgrupo.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al cargar subgrupos';
      throw Exception(msg);
    }
  }

  Future<Subgrupo> createSubgrupo({
    required String nodoId,
    required String nombre,
    String? descripcion,
    bool esPrivado = false,
  }) async {
    try {
      final response = await _client.post(
        '/nodos/$nodoId/subgrupos',
        data: {
          'nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
          'es_privado': esPrivado,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['subgrupo'] != null) {
        return Subgrupo.fromJson(data['subgrupo'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Error al crear subgrupo');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al crear subgrupo';
      throw Exception(msg);
    }
  }

  Future<void> joinSubgrupo({
    required String nodoId,
    required String subgrupoId,
  }) async {
    try {
      await _client.post('/nodos/$nodoId/subgrupos/$subgrupoId/join');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al unirse al subgrupo';
      throw Exception(msg);
    }
  }

  Future<void> leaveSubgrupo({
    required String nodoId,
    required String subgrupoId,
  }) async {
    try {
      await _client.post('/nodos/$nodoId/subgrupos/$subgrupoId/leave');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al salir del subgrupo';
      throw Exception(msg);
    }
  }

  Future<void> deleteSubgrupo({
    required String nodoId,
    required String subgrupoId,
  }) async {
    try {
      await _client.delete('/nodos/$nodoId/subgrupos/$subgrupoId');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al eliminar subgrupo';
      throw Exception(msg);
    }
  }

  Future<List<SubgrupoMiembro>> fetchSubgrupoMiembros({
    required String nodoId,
    required String subgrupoId,
  }) async {
    try {
      final response = await _client.get('/nodos/$nodoId/subgrupos/$subgrupoId/miembros');
      final data = response.data as Map<String, dynamic>;
      final list = (data['miembros'] as List<dynamic>?) ?? [];
      return list.map((e) => SubgrupoMiembro.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al cargar miembros del subgrupo';
      throw Exception(msg);
    }
  }
}

class SubgrupoMiembro {
  final String userId;
  final String name;
  final String email;
  final String? avatarColor;
  final DateTime joinedAt;

  const SubgrupoMiembro({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarColor,
    required this.joinedAt,
  });

  factory SubgrupoMiembro.fromJson(Map<String, dynamic> json) {
    return SubgrupoMiembro(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarColor: json['avatar_color'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

final subgruposRepositoryProvider = Provider<SubgruposRepository>((ref) {
  return SubgruposRepository();
});

