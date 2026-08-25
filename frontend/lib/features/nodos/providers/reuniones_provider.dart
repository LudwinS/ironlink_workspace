import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reuniones_repository.dart';

class ReunionesState {
  final List<Reunion> reuniones;
  final bool isLoading;
  final String? errorMessage;

  const ReunionesState({
    this.reuniones = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ReunionesState copyWith({
    List<Reunion>? reuniones,
    bool? isLoading,
    String? errorMessage,
    bool clearErrors = false,
  }) {
    return ReunionesState(
      reuniones: reuniones ?? this.reuniones,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReunionesNotifier extends StateNotifier<ReunionesState> {
  final ReunionesRepository _repository;
  final String? _nodoId;

  ReunionesNotifier(this._repository, this._nodoId) : super(const ReunionesState()) {
    if (_nodoId != null && _nodoId.isNotEmpty) {
      loadReuniones();
    }
  }

  Future<void> loadReuniones() async {
    if (_nodoId == null) return;
    state = state.copyWith(isLoading: true, clearErrors: true);
    try {
      final list = await _repository.fetchReuniones(_nodoId);
      state = state.copyWith(reuniones: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createReunion({
    required String titulo,
    String? descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? enlaceReunion,
  }) async {
    if (_nodoId == null) return false;
    state = state.copyWith(isLoading: true, clearErrors: true);
    try {
      final newReunion = await _repository.createReunion(
        nodoId: _nodoId,
        titulo: titulo,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        enlaceReunion: enlaceReunion,
      );
      state = state.copyWith(
        reuniones: [...state.reuniones, newReunion],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteReunion(String reunionId) async {
    if (_nodoId == null) return false;
    try {
      await _repository.deleteReunion(nodoId: _nodoId, reunionId: reunionId);
      state = state.copyWith(
        reuniones: state.reuniones.where((r) => r.id != reunionId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final reunionesProvider = StateNotifierProvider.family<ReunionesNotifier, ReunionesState, String>((ref, nodoId) {
  final repo = ref.watch(reunionesRepositoryProvider);
  return ReunionesNotifier(repo, nodoId);
});
