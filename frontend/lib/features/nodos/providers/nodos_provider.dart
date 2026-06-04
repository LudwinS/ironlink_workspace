import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nodos_repository.dart';
import '../../../core/security/secure_vault.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estado del módulo Nodos
// ─────────────────────────────────────────────────────────────────────────────

enum NodosStatus { initial, loading, loaded, error }

class NodosState {
  final NodosStatus status;
  final List<Nodo> nodos;
  final String? errorMessage;
  final String? successMessage;

  const NodosState({
    this.status = NodosStatus.initial,
    this.nodos = const [],
    this.errorMessage,
    this.successMessage,
  });

  NodosState copyWith({
    NodosStatus? status,
    List<Nodo>? nodos,
    String? errorMessage,
    String? successMessage,
  }) {
    return NodosState(
      status: status ?? this.status,
      nodos: nodos ?? this.nodos,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  /// Nodo activo más reciente (si existe)
  Nodo? get nodoActivo {
    final activos = nodos.where((n) => n.isActive).toList();
    if (activos.isEmpty) return null;
    activos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activos.first;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NodosNotifier extends StateNotifier<NodosState> {
  final NodosRepository _repository;

  NodosNotifier(this._repository) : super(const NodosState());

  /// Carga los nodos del usuario.
  Future<void> loadNodos() async {
    state = state.copyWith(status: NodosStatus.loading);
    try {
      final nodos = await _repository.fetchNodos();
      state = state.copyWith(status: NodosStatus.loaded, nodos: nodos);
    } catch (e) {
      state = state.copyWith(
        status: NodosStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Crea un nodo nuevo y lo agrega a la lista local.
  Future<bool> createNodo({
    required String nombre,
    String? descripcion,
  }) async {
    state = state.copyWith(status: NodosStatus.loading);
    try {
      final nodo = await _repository.createNodo(
        nombre: nombre,
        descripcion: descripcion,
      );
      state = state.copyWith(
        status: NodosStatus.loaded,
        nodos: [nodo, ...state.nodos],
        successMessage: 'Nodo "$nombre" creado exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: NodosStatus.loaded,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Se une a un nodo mediante token de acceso.
  Future<bool> joinNodo(String token) async {
    state = state.copyWith(status: NodosStatus.loading);
    try {
      final nodo = await _repository.joinNodo(token);
      // Evitar duplicados
      final exists = state.nodos.any((n) => n.id == nodo.id);
      final updatedNodos = exists ? state.nodos : [nodo, ...state.nodos];
      state = state.copyWith(
        status: NodosStatus.loaded,
        nodos: updatedNodos,
        successMessage: 'Te has unido al nodo "${nodo.nombre}"',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: NodosStatus.loaded,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Limpia los mensajes temporales.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers de Riverpod
// ─────────────────────────────────────────────────────────────────────────────

final nodosRepositoryProvider =
    Provider<NodosRepository>((ref) => NodosRepository());

final nodosProvider =
    StateNotifierProvider<NodosNotifier, NodosState>((ref) {
  final repo = ref.watch(nodosRepositoryProvider);
  return NodosNotifier(repo);
});

/// Provider para el rol del usuario (leído de SecureVault).
final userRoleProvider = FutureProvider<String>((ref) async {
  return await SecureVault.getRole() ?? 'MEMBER';
});

/// Provider para el nombre de usuario.
final usernameProvider = FutureProvider<String>((ref) async {
  return await SecureVault.getUsername() ?? 'Usuario';
});

/// Provider para el email del usuario.
final userEmailProvider = FutureProvider<String>((ref) async {
  return await SecureVault.getEmail() ?? '';
});
