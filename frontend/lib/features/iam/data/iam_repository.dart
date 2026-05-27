import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_vault.dart';

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
        '/register', // Endpoint directo según tu main.rs
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );
      
      // Dado que tu backend devuelve un texto plano (String), leemos la respuesta directa
      return response.data.toString();
    } on DioException catch (e) {
      final errorMessage = e.response?.data?.toString() ?? 'Fallo al conectar con el servidor de registro';
      throw Exception(errorMessage);
    }
  }

  /// Envía petición de inicio de sesión (Placeholder para cuando se implemente en tu backend)
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Endpoint simulado para conectar en el futuro
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
        '/resend-verification', // Se mapeará con el endpoint del backend
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
