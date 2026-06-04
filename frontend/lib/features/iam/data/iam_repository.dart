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

  /// Envía petición de inicio de sesión.
  /// Parsea la respuesta JWT: { access_token, refresh_token, user: { id, name, email, role } }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _client.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Extraer tokens
      final accessToken = data['access_token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';

      // Extraer datos de usuario del objeto anidado 'user'
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final username = user['name'] as String? ?? 'User';
      final userEmail = user['email'] as String? ?? email;
      final role = user['role'] as String? ?? 'Miembro';

      // Guardar en SecureVault
      await SecureVault.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        username: username,
        email: userEmail,
        role: role,
        rememberMe: rememberMe,
      );

      return {
        'username': username,
        'email': userEmail,
        'role': role,
      };
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw Exception(responseData['message'] ?? 'Credenciales incorrectas');
      }
      throw Exception(responseData?.toString() ?? 'Fallo de autenticación de red');
    }
  }

  /// Solicita el envío de verificación (código o enlace).
  /// [method] puede ser 'code' o 'link'.
  Future<String> requestVerification({
    required String email,
    required String method,
  }) async {
    try {
      final response = await _client.post(
        '/request-verification',
        data: {
          'email': email,
          'method': method,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'Verificación enviada.';
      }
      return response.data.toString();
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw Exception(responseData['message'] ?? 'Error al solicitar verificación');
      }
      throw Exception(responseData?.toString() ?? 'Error al solicitar verificación');
    }
  }

  /// Verifica el correo con un código OTP de 6 dígitos.
  /// Retorna datos del usuario verificado.
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        '/verify-email',
        data: {
          'email': email,
          'code': code,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'name': data['name'] ?? data['user']?['name'] ?? '',
        'email': data['email'] ?? data['user']?['email'] ?? email,
        'carnet': data['carnet'] ?? data['user']?['carnet'] ?? '',
        'status': data['status'] ?? data['user']?['status'] ?? 'Activo',
        'message': data['message'] ?? 'Cuenta verificada exitosamente.',
      };
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw Exception(responseData['message'] ?? 'Código de verificación inválido');
      }
      throw Exception(responseData?.toString() ?? 'Error al verificar el correo');
    }
  }

  /// Verifica el correo mediante un token de enlace.
  /// Retorna datos del usuario verificado.
  Future<Map<String, dynamic>> verifyLink(String token) async {
    try {
      final response = await _client.get('/verify-link/$token');

      final data = response.data as Map<String, dynamic>;
      return {
        'name': data['name'] ?? data['user']?['name'] ?? '',
        'email': data['email'] ?? data['user']?['email'] ?? '',
        'carnet': data['carnet'] ?? data['user']?['carnet'] ?? '',
        'status': data['status'] ?? data['user']?['status'] ?? 'Activo',
        'message': data['message'] ?? 'Cuenta verificada exitosamente.',
      };
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw Exception(responseData['message'] ?? 'Enlace de verificación inválido o expirado');
      }
      throw Exception(responseData?.toString() ?? 'Error al verificar el enlace');
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
