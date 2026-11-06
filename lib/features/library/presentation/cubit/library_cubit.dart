import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/repositories/library_repository.dart';
import 'library_state.dart';

/// Cubit que gestiona la carga, búsqueda, filtrado y favoritos de la Biblioteca.
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository libraryRepository;

  Timer? _debounceTimer;
  int _latestRequestId = 0;

  LibraryCubit({required this.libraryRepository}) : super(const LibraryInitial());

  /// Carga inicial o recarga de la biblioteca con los filtros indicados o existentes.
  Future<void> loadLibrary({
    ContentType? type,
    bool clearType = false,
    String? query,
    bool? favoriteOnly,
  }) async {
    final effectiveType = clearType ? null : (type ?? state.activeFilter);
    final effectiveQuery = query ?? state.searchQuery;
    final effectiveFavorite = favoriteOnly ?? state.favoriteOnly;

    emit(LibraryLoading(
      activeFilter: effectiveType,
      searchQuery: effectiveQuery,
      favoriteOnly: effectiveFavorite,
    ));

    final requestId = ++_latestRequestId;

    try {
      final items = await libraryRepository.getLibraryItems(
        type: effectiveType,
        query: effectiveQuery.isEmpty ? null : effectiveQuery,
        favorite: effectiveFavorite ? true : null,
      );

      // Si una petición más reciente fue emitida mientras esta esperaba, descartar
      if (requestId != _latestRequestId) {
        return;
      }

      if (items.isEmpty) {
        emit(LibraryEmpty(
          activeFilter: effectiveType,
          searchQuery: effectiveQuery,
          favoriteOnly: effectiveFavorite,
        ));
      } else {
        emit(LibraryLoaded(
          items: items,
          activeFilter: effectiveType,
          searchQuery: effectiveQuery,
          favoriteOnly: effectiveFavorite,
        ));
      }
    } on Failure catch (failure) {
      if (requestId != _latestRequestId) return;
      final previous = (state is LibraryLoaded) ? (state as LibraryLoaded).items : <LibraryItemEntity>[];
      emit(LibraryError(
        message: failure.message,
        previousItems: previous,
        activeFilter: effectiveType,
        searchQuery: effectiveQuery,
        favoriteOnly: effectiveFavorite,
      ));
    } catch (e) {
      if (requestId != _latestRequestId) return;
      final previous = (state is LibraryLoaded) ? (state as LibraryLoaded).items : <LibraryItemEntity>[];
      emit(LibraryError(
        message: 'No pudimos conectar con la biblioteca. Revisa tu conexión e intenta de nuevo.',
        previousItems: previous,
        activeFilter: effectiveType,
        searchQuery: effectiveQuery,
        favoriteOnly: effectiveFavorite,
      ));
    }
  }

  /// Aplica o alterna el filtro por tipo de contenido (`image`, `story`, `music` o null para todos).
  Future<void> setTypeFilter(ContentType? type) async {
    if (state.activeFilter == type) return;
    await loadLibrary(
      type: type,
      clearType: type == null,
    );
  }

  /// Alterna la vista para mostrar exclusivamente elementos favoritos.
  Future<void> setFavoriteOnly(bool favoriteOnly) async {
    if (state.favoriteOnly == favoriteOnly) return;
    await loadLibrary(favoriteOnly: favoriteOnly);
  }

  /// Búsqueda reactiva con debounce de 400ms para no saturar el backend.
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.searchDebounce, () {
      loadLibrary(query: query.trim());
    });
  }

  /// Búsqueda inmediata (ej: al presionar Enter en el teclado o botón Buscar).
  Future<void> searchImmediate(String query) async {
    _debounceTimer?.cancel();
    await loadLibrary(query: query.trim());
  }

  /// Alterna el estado de favorito de un elemento (`PATCH /api/v1/library/{id}`).
  Future<void> toggleFavorite(LibraryItemEntity item) async {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    final targetId = item.id;
    final newFavoriteStatus = !item.favorite;

    // Marcador visual de operación en curso
    emit(currentState.copyWith(togglingFavoriteId: targetId));

    try {
      final updatedItem = await libraryRepository.toggleFavorite(
        targetId,
        newFavoriteStatus,
      );

      // Reemplazar el ítem actualizado en la lista
      List<LibraryItemEntity> updatedList;
      if (currentState.favoriteOnly && !newFavoriteStatus) {
        // Si el filtro de favoritos está activo y se desmarca, se remueve de la vista
        updatedList = currentState.items.where((i) => i.id != targetId).toList();
      } else {
        updatedList = currentState.items.map((i) {
          return i.id == targetId ? updatedItem : i;
        }).toList();
      }

      if (updatedList.isEmpty) {
        emit(LibraryEmpty(
          activeFilter: currentState.activeFilter,
          searchQuery: currentState.searchQuery,
          favoriteOnly: currentState.favoriteOnly,
        ));
      } else {
        emit(currentState.copyWith(
          items: updatedList,
          clearToggling: true,
        ));
      }
    } on Failure catch (failure) {
      // Revertir estado de carga y notificar error sin alterar los datos previos
      emit(LibraryError(
        message: failure.message,
        previousItems: currentState.items,
        activeFilter: currentState.activeFilter,
        searchQuery: currentState.searchQuery,
        favoriteOnly: currentState.favoriteOnly,
      ));
      emit(currentState.copyWith(clearToggling: true));
    } catch (_) {
      emit(LibraryError(
        message: 'No pudimos actualizar el favorito. Inténtalo de nuevo.',
        previousItems: currentState.items,
        activeFilter: currentState.activeFilter,
        searchQuery: currentState.searchQuery,
        favoriteOnly: currentState.favoriteOnly,
      ));
      emit(currentState.copyWith(clearToggling: true));
    }
  }

  /// Refresco manual de la lista (Pull-to-refresh).
  Future<void> refresh() async {
    await loadLibrary();
  }

  /// Restablece el estado de la biblioteca al cerrar sesión.
  void clearSession() {
    _debounceTimer?.cancel();
    emit(const LibraryInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

