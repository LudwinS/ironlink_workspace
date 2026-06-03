import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_vault.dart';

/// Excepción personalizada para errores de validación con errores por campo.
class FieldValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  FieldValidationException({required this.message, required this.fieldErrors});

  @override
  String toString() => message;
}

class IamRepository {
  final Dio _client = ApiClient.instance;

  /// Envía petición de registro al backend de Rust.
  Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'Registro exitoso.';
      }
      return response.data.toString();
    } on DioException catch (e) {
      final responseData = e.response?.data;

      // Parsear respuesta JSON estructurada del backend
      if (responseData is Map<String, dynamic>) {
        final fieldErrors = <String, String>{};
        if (responseData['field_errors'] != null && responseData['field_errors'] is Map) {
          (responseData['field_errors'] as Map).forEach((key, value) {
            fieldErrors[key.toString()] = value.toString();
          });
        }

        if (fieldErrors.isNotEmpty) {
          throw FieldValidationException(
            message: responseData['message'] ?? 'Error de validación',
            fieldErrors: fieldErrors,
          );
        }

        throw Exception(responseData['message'] ?? 'Error en el registro');
      }

      throw Exception(e.response?.data?.toString() ?? 'Fallo al conectar con el servidor de registro');
    }
  }

  /// Envía petición de inicio de sesión
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      await SecureVault.saveAuthData(
        accessToken: data['access_token'] ?? 'simulated_jwt_token',
        refreshToken: data['refresh_token'] ?? 'simulated_refresh_token',
        username: data['username'] ?? 'User',
        email: data['email'] ?? email,
        role: data['role'] ?? 'Miembro',
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data?.toString() ?? 'Fallo de autenticación de red';
      throw Exception(errorMessage);
    }
  }

  /// Envía petición de reenvío de correo de activación de cuenta.
  Future<String> resendVerificationEmail({
    required String email,
  }) async {
    try {
      final response = await _client.post(
        '/resend-verification',
        data: {
          'email': email,
        },
      );

      return response.data.toString();
    } on DioException catch (e) {
      final errorMessage = e.response?.data?.toString() ?? 'Error al solicitar el reenvío de código';
      throw Exception(errorMessage);
    }
  }
}
