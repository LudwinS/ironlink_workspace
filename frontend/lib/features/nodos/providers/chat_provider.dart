import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nodos_repository.dart';
import '../data/subgrupos_repository.dart';
import 'nodos_provider.dart';

final selectedSubgrupoProvider = StateProvider<Subgrupo?>((ref) => null);

class ChatMessagesState {
  final List<Mensaje> mensajes;
  final bool loading;
  final String? error;

  const ChatMessagesState({
    this.mensajes = const [],
    this.loading = false,
    this.error,
  });

  ChatMessagesState copyWith({
    List<Mensaje>? mensajes,
    bool? loading,
    String? error,
  }) {
    return ChatMessagesState(
      mensajes: mensajes ?? this.mensajes,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final NodosRepository _repository;
  final Ref _ref;
  Timer? _timer;
  String? _activeNodoId;
  String? _activeSubgrupoId;

  ChatMessagesNotifier(this._repository, this._ref) : super(const ChatMessagesState()) {
    // Escuchar el nodo seleccionado para cargar mensajes automáticamente
    _ref.listen<Nodo?>(selectedNodoProvider, (previous, next) {
      if (next == null) {
        _activeNodoId = null;
        _activeSubgrupoId = null;
        _timer?.cancel();
        state = const ChatMessagesState();
      } else {
        _activeNodoId = next.id;
        _activeSubgrupoId = _ref.read(selectedSubgrupoProvider)?.id;
        loadMensajes();
        _startPolling();
      }
    });

    // Escuchar el subgrupo seleccionado dentro del nodo
    _ref.listen<Subgrupo?>(selectedSubgrupoProvider, (previous, next) {
      final currentNodo = _ref.read(selectedNodoProvider);
      if (currentNodo != null) {
        _activeNodoId = currentNodo.id;
        _activeSubgrupoId = next?.id;
        state = const ChatMessagesState(loading: true);
        loadMensajes();
        _startPolling();
      }
    });

    // Si ya hay un nodo seleccionado al inicializar
    final initialNodo = _ref.read(selectedNodoProvider);
    if (initialNodo != null) {
      _activeNodoId = initialNodo.id;
      _activeSubgrupoId = _ref.read(selectedSubgrupoProvider)?.id;
      loadMensajes();
      _startPolling();
    }
  }

  Future<void> loadMensajes({bool silent = false}) async {
    final nodoId = _activeNodoId;
    final subgrupoId = _activeSubgrupoId;
    if (nodoId == null) return;

    if (!silent && state.mensajes.isEmpty) {
      state = state.copyWith(loading: true);
    }

    try {
      final list = await _repository.fetchMensajes(nodoId, subgrupoId: subgrupoId);
      // Evitar sobreescribir si ya cambiamos de nodo o subgrupo
      if (_activeNodoId == nodoId && _activeSubgrupoId == subgrupoId) {
        state = state.copyWith(mensajes: list, loading: false, error: null);
      }
    } catch (e) {
      if (_activeNodoId == nodoId && _activeSubgrupoId == subgrupoId && !silent) {
        state = state.copyWith(
          error: e.toString().replaceAll('Exception: ', ''),
          loading: false,
        );
      }
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadMensajes(silent: true);
    });
  }

  Future<bool> sendMensaje(String contenido) async {
    final nodoId = _activeNodoId;
    final subgrupoId = _activeSubgrupoId;
    if (nodoId == null || contenido.trim().isEmpty) return false;

    try {
      final msg = await _repository.sendMensaje(nodoId, contenido.trim(), subgrupoId: subgrupoId);
      if (_activeNodoId == nodoId && _activeSubgrupoId == subgrupoId) {
        state = state.copyWith(
          mensajes: [...state.mensajes, msg],
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final chatMessagesProvider =
    StateNotifierProvider.autoDispose<ChatMessagesNotifier, ChatMessagesState>((ref) {
  final repo = ref.watch(nodosRepositoryProvider);
  return ChatMessagesNotifier(repo, ref);
});

