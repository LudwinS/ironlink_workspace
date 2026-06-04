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
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      verifiedUserData: verifiedUserData ?? this.verifiedUserData,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IamRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    checkPersistedSession();
  }

  Future<void> checkPersistedSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    // Si no se marcó "Recordarme", limpiar los datos al iniciar la app
    final rememberMe = await SecureVault.getRememberMe();
    if (!rememberMe) {
      await SecureVault.clearAuthData();
    }

    final hasSession = await SecureVault.hasSession();
    if (hasSession) {
      final username = await SecureVault.getUsername();
      final email = await SecureVault.getEmail();
      final role = await SecureVault.getRole();
      state = AuthState(
        status: AuthStatus.authenticated,
        username: username,
        email: email,
        role: role,
      );
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Limpia los errores de campo para permitir reintento limpio
  void clearFieldErrors() {
    state = state.copyWith(
      fieldErrors: null,
      errorMessage: null,
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
      errorMessage: null,
      successMessage: null,
      fieldErrors: null,
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
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null, fieldErrors: null);
    try {
      final userData = await _repository.login(email: email, password: password, rememberMe: rememberMe);

      state = AuthState(
        status: AuthStatus.authenticated,
        username: userData['username'],
        email: userData['email'],
        role: userData['role'],
      );
      return true;
    } catch (e) {
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
      errorMessage: null,
      successMessage: null,
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
      errorMessage: null,
      successMessage: null,
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
      errorMessage: null,
      successMessage: null,
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
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null);
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
