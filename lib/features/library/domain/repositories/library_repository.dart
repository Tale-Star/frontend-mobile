import '../entities/library_item_entity.dart';

/// Contrato abstracto del repositorio de biblioteca.
abstract class LibraryRepository {
  /// Lista los elementos de la biblioteca del usuario autenticado,
  /// admitiendo filtros oficiales de tipo, búsqueda de texto 'q' y favoritos.
  Future<List<LibraryItemEntity>> getLibraryItems({
    ContentType? type,
    String? query,
    bool? favorite,
  });

  /// Obtiene los detalles de un elemento individual por su ID.
  Future<LibraryItemEntity> getLibraryItem(String id);

  /// Modifica el estado de favorito de un elemento (`PATCH /api/v1/library/{id}`).
  Future<LibraryItemEntity> toggleFavorite(String id, bool newFavoriteStatus);
}

