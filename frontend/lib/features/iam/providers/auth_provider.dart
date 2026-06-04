import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/iam_repository.dart';
import '../../../core/security/secure_vault.dart';

enum AuthStatus { initial, loading, unauthenticated, verificationPending, verified, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String>? fieldErrors;
  /// Datos del usuario verificado (name, email, carnet, status) tras verificación exitosa.
  final Map<String, dynamic>? verifiedUserData;

  AuthState({
    this.status = AuthStatus.initial,
    this.username,
    this.email,
    this.role,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors,
    this.verifiedUserData,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? email,
    String? role,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    Map<String, dynamic>? verifiedUserData,
    bool clearErrors = false,
    bool clearSuccess = false,
    bool clearVerifiedUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      fieldErrors: clearErrors ? null : (fieldErrors ?? this.fieldErrors),
      verifiedUserData: clearVerifiedUser ? null : (verifiedUserData ?? this.verifiedUserData),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IamRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    checkPersistedSession();
  }

  Future<void> checkPersistedSession() async {
    print("DEBUG: AuthNotifier - checkPersistedSession() iniciado");
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final rememberMe = await SecureVault.getRememberMe();
      print("DEBUG: AuthNotifier - rememberMe leído de SecureVault: $rememberMe");
      if (!rememberMe) {
        print("DEBUG: AuthNotifier - rememberMe es falso, limpiando session data...");
        await SecureVault.clearAuthData();
      }

      final hasSession = await SecureVault.hasSession();
      print("DEBUG: AuthNotifier - hasSession check: $hasSession");
      if (hasSession) {
        final username = await SecureVault.getUsername();
        final email = await SecureVault.getEmail();
        final role = await SecureVault.getRole();
        print("DEBUG: AuthNotifier - Sesión persistida encontrada. Usuario: $username, Rol: $role");
        state = AuthState(
          status: AuthStatus.authenticated,
          username: username,
          email: email,
          role: role,
        );
      } else {
        print("DEBUG: AuthNotifier - No hay sesión persistida activa");
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print("DEBUG: AuthNotifier - ERROR en checkPersistedSession: $e");
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Limpia los errores de campo para permitir reintento limpio
  void clearFieldErrors() {
    state = state.copyWith(
      clearErrors: true,
    );
  }

  /// Registro de usuario conectado al backend de Rust
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      final message = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        successMessage: message,
      );
      return true;
    } on FieldValidationException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    print("DEBUG: AuthNotifier - login() iniciado. Email: $email, rememberMe: $rememberMe");
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      print("DEBUG: AuthNotifier - Llamando a _repository.login...");
      final userData = await _repository.login(email: email, password: password, rememberMe: rememberMe);
      print("DEBUG: AuthNotifier - _repository.login exitoso. Datos retornados: $userData");

      state = AuthState(
        status: AuthStatus.authenticated,
        username: userData['username'],
        email: userData['email'],
        role: userData['role'],
      );
      return true;
    } catch (e) {
      print("DEBUG: AuthNotifier - ERROR en login(): $e");
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Solicita envío de verificación (código o enlace).
  Future<bool> requestVerification(String email, String method) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      final message = await _repository.requestVerification(
        email: email,
        method: method,
      );
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        successMessage: message,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Verifica el correo con código OTP.
  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      final userData = await _repository.verifyEmail(email: email, code: code);
      state = AuthState(
        status: AuthStatus.verified,
        email: email,
        username: userData['name'],
        verifiedUserData: userData,
        successMessage: userData['message'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Verifica el correo mediante token de enlace.
  Future<bool> verifyLink(String token) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      final userData = await _repository.verifyLink(token);
      state = AuthState(
        status: AuthStatus.verified,
        email: userData['email'],
        username: userData['name'],
        verifiedUserData: userData,
        successMessage: userData['message'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> resendVerification(String email) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearErrors: true,
      clearSuccess: true,
    );
    try {
      final message = await _repository.resendVerificationEmail(email: email);
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        successMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        email: email,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await SecureVault.clearAuthData();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final iamRepositoryProvider = Provider<IamRepository>((ref) => IamRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(iamRepositoryProvider);
  return AuthNotifier(repo);
});
