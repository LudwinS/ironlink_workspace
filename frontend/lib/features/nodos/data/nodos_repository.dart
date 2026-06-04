import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de datos: Nodo
// ─────────────────────────────────────────────────────────────────────────────

class Nodo {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tokenAcceso;
  final String creadorId;
  final String estado; // 'active' o 'inactive'
  final int miembrosCount;
  final String? creadorNombre;
  final DateTime createdAt;

  const Nodo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tokenAcceso,
    required this.creadorId,
    required this.estado,
    required this.miembrosCount,
    this.creadorNombre,
    required this.createdAt,
  });

  factory Nodo.fromJson(Map<String, dynamic> json) {
    return Nodo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      tokenAcceso: json['token_acceso'] as String? ?? '',
      creadorId: json['creador_id'] as String? ?? '',
      estado: json['estado'] as String? ?? 'active',
      miembrosCount: (json['miembros_count'] as num?)?.toInt() ?? 0,
      creadorNombre: json['creador_nombre'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'token_acceso': tokenAcceso,
        'creador_id': creadorId,
        'estado': estado,
        'miembros_count': miembrosCount,
        'creador_nombre': creadorNombre,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isActive => estado == 'active';
}

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio de Nodos
// ─────────────────────────────────────────────────────────────────────────────

class NodosRepository {
  final Dio _client = ApiClient.instance;

  /// Obtiene la lista de nodos del usuario autenticado.
  /// GET /nodos
  Future<List<Nodo>> fetchNodos() async {
    try {
      final response = await _client.get('/nodos');
      final data = response.data;

      if (data is List) {
        return data
            .map((e) => Nodo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data is Map<String, dynamic> && data['nodos'] is List) {
        return (data['nodos'] as List)
            .map((e) => Nodo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Error al obtener los nodos');
      throw Exception(msg);
    }
  }

  /// Crea un nuevo nodo.
  /// POST /nodos
  Future<Nodo> createNodo({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await _client.post(
        '/nodos',
        data: {
          'nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'descripcion': descripcion,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // El backend puede devolver el nodo directamente o dentro de una clave
        if (data.containsKey('id')) {
          return Nodo.fromJson(data);
        }
        if (data['nodo'] is Map<String, dynamic>) {
          return Nodo.fromJson(data['nodo'] as Map<String, dynamic>);
        }
      }

      throw Exception('Respuesta inesperada del servidor al crear nodo');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Error al crear el nodo');
      throw Exception(msg);
    }
  }

  /// Se une a un nodo existente mediante token de acceso.
  /// POST /nodos/join/:token
  Future<Nodo> joinNodo(String token) async {
    try {
      final sanitizedToken = token.trim();
      final response = await _client.post('/nodos/join/$sanitizedToken');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('id')) {
          return Nodo.fromJson(data);
        }
        if (data['nodo'] is Map<String, dynamic>) {
          return Nodo.fromJson(data['nodo'] as Map<String, dynamic>);
        }
      }

      throw Exception('Respuesta inesperada del servidor al unirse al nodo');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Error al unirse al nodo');
      throw Exception(msg);
    }
  }

  /// Extrae un mensaje legible de una respuesta de error Dio.
  String _extractErrorMessage(DioException e, String fallback) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      return responseData['message']?.toString() ?? fallback;
    }
    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }
    return fallback;
  }
}
