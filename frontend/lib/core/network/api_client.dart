import 'package:dio/dio.dart';
import '../security/secure_vault.dart';

class ApiClient {
  static final Dio instance = _initDio();

  static Dio _initDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8080', // Conecta directamente con el backend en localhost:8080
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await SecureVault.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await SecureVault.clearAuthData();
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
