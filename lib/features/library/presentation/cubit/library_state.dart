import 'package:equatable/equatable.dart';
import '../../domain/entities/library_item_entity.dart';

/// Estados reactivos para la exploración de la biblioteca Tale Star.
abstract class LibraryState extends Equatable {
  final ContentType? activeFilter;
  final String searchQuery;
  final bool favoriteOnly;

  const LibraryState({
    this.activeFilter,
    this.searchQuery = '',
    this.favoriteOnly = false,
  });

  @override
  List<Object?> get props => [activeFilter, searchQuery, favoriteOnly];
}

/// Estado inicial antes de la primera carga.
class LibraryInitial extends LibraryState {
  const LibraryInitial({
    super.activeFilter,
    super.searchQuery,
    super.favoriteOnly,
  });
}

/// Estado de carga o actualización en progreso.
class LibraryLoading extends LibraryState {
  const LibraryLoading({
    super.activeFilter,
    super.searchQuery,
    super.favoriteOnly,
  });
}

/// Estado con datos disponibles para mostrar.
class LibraryLoaded extends LibraryState {
  final List<LibraryItemEntity> items;
  final String? togglingFavoriteId;

  const LibraryLoaded({
    required this.items,
    super.activeFilter,
    super.searchQuery,
    super.favoriteOnly,
    this.togglingFavoriteId,
  });

  LibraryLoaded copyWith({
    List<LibraryItemEntity>? items,
    ContentType? activeFilter,
    bool clearActiveFilter = false,
    String? searchQuery,
    bool? favoriteOnly,
    String? togglingFavoriteId,
    bool clearToggling = false,
  }) {
    return LibraryLoaded(
      items: items ?? this.items,
      activeFilter: clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      togglingFavoriteId: clearToggling ? null : (togglingFavoriteId ?? this.togglingFavoriteId),
    );
  }

  @override
  List<Object?> get props => [
        items,
        activeFilter,
        searchQuery,
        favoriteOnly,
        togglingFavoriteId,
      ];
}

/// Estado cuando la consulta no arrojó resultados.
class LibraryEmpty extends LibraryState {
  const LibraryEmpty({
    super.activeFilter,
    super.searchQuery,
    super.favoriteOnly,
  });
}

/// Estado ante un fallo de red o servidor.
class LibraryError extends LibraryState {
  final String message;
  final List<LibraryItemEntity> previousItems;

  const LibraryError({
    required this.message,
    this.previousItems = const [],
    super.activeFilter,
    super.searchQuery,
    super.favoriteOnly,
  });

  @override
  List<Object?> get props => [
        message,
        previousItems,
        activeFilter,
        searchQuery,
        favoriteOnly,
      ];
}

