import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/iam_repository.dart';
import '../../../core/security/secure_vault.dart';

enum AuthStatus { initial, loading, unauthenticated, verificationPending, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? successMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.username,
    this.email,
    this.role,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? email,
    String? role,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
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

  /// Registro de usuario conectado al backend de Rust
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null);
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
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null);
    try {
      await _repository.login(email: email, password: password);
      final username = await SecureVault.getUsername();
      final userEmail = await SecureVault.getEmail();
      final role = await SecureVault.getRole();

      state = AuthState(
        status: AuthStatus.authenticated,
        username: username,
        email: userEmail,
        role: role,
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
