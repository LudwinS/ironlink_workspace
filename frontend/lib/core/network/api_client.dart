import 'package:dio/dio.dart';
import '../security/secure_vault.dart';

class ApiClient {
  static final Dio _dio = Dio(
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

  static bool _initialized = false;

  static Dio get instance {
    if (!_initialized) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final accessToken = await SecureVault.getAccessToken();
            print("ApiClient - Enviando petición a: ${options.path} - Token longitud: ${accessToken?.length ?? 0}");
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            return handler.next(options);
          },
          onError: (DioException error, handler) async {
            print("ApiClient - ERROR en petición a: ${error.requestOptions.path} - Código: ${error.response?.statusCode}");
            if (error.response?.statusCode == 401) {
              print("ApiClient - ERROR 401: Sesión expirada, borrando datos de SecureVault.");
              await SecureVault.clearAuthData();
            }
            return handler.next(error);
          },
        ),
      );
      _initialized = true;
    }
    return _dio;
  }
}
