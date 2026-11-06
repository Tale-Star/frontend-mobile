import '../../core/error/failures.dart';
import '../features/library/data/models/library_item_model.dart';
import '../features/library/domain/entities/library_item_entity.dart';
import '../features/library/domain/repositories/library_repository.dart';
import 'fixtures/demo_library_fixtures.dart';

/// Implementación simulada de [LibraryRepository] para el Modo Demostración de Tale Star.
///
/// Gestiona una colección inmutable/mutable en memoria a partir de los fixtures oficiales,
/// permitiendo probar búsquedas, filtros por tipo, alternancia de favoritos, pull-to-refresh
/// y simulación de errores en dispositivos físicos sin un backend de staging.
class MockLibraryRepository implements LibraryRepository {
  List<LibraryItemEntity> _items = [];

  bool simulateNetworkError = false;
  bool simulateEmptyResponse = false;

  MockLibraryRepository() {
    resetToFixtures();
  }

  /// Restablece la colección en memoria a su estado inicial de fixtures.
  void resetToFixtures() {
    _items = kDemoLibraryFixtures
        .map<LibraryItemEntity>((json) => LibraryItemModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<LibraryItemEntity>> getLibraryItems({
    ContentType? type,
    String? query,
    bool? favorite,
  }) async {
    // Simula latencia natural de red (250ms)
    await Future.delayed(const Duration(milliseconds: 250));

    // Simulación reactiva mediante banderas o términos de búsqueda
    final normalizedQuery = (query ?? '').toLowerCase().trim();

    if (simulateNetworkError || normalizedQuery.contains('error_red') || normalizedQuery.contains('simular_error')) {
      throw const NetworkFailure(
        message: 'No pudimos conectar con la biblioteca. Revisa tu conexión a internet.',
      );
    }

    if (normalizedQuery.contains('error_servidor')) {
      throw const ServerFailure(
        message: 'Error interno del servidor al cargar los contenidos.',
        statusCode: 500,
      );
    }

    if (simulateEmptyResponse || normalizedQuery.contains('vacio') || normalizedQuery.contains('sin_resultados')) {
      return [];
    }

    var result = List<LibraryItemEntity>.from(_items);

    // Filtro por tipo de contenido
    if (type != null) {
      result = result.where((item) => item.type == type).toList();
    }

    // Filtro por favoritos
    if (favorite == true) {
      result = result.where((item) => item.favorite).toList();
    }

    // Búsqueda reactiva por texto en nombre y descripción
    if (normalizedQuery.isNotEmpty) {
      result = result.where((item) {
        final matchName = item.name.toLowerCase().contains(normalizedQuery);
        final matchDesc = item.description.toLowerCase().contains(normalizedQuery);
        return matchName || matchDesc;
      }).toList();
    }

    return result;
  }

  @override
  Future<LibraryItemEntity> getLibraryItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final match = _items.where((i) => i.id == id);
    if (match.isEmpty) {
      throw const ServerFailure(
        message: 'No encontramos el elemento solicitado en tu biblioteca.',
        statusCode: 404,
      );
    }

    return match.first;
  }

  @override
  Future<LibraryItemEntity> toggleFavorite(String id, bool newFavoriteStatus) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (simulateNetworkError) {
      throw const NetworkFailure(
        message: 'No pudimos sincronizar tu favorito. Comprueba tu conexión.',
      );
    }

    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw const ServerFailure(
        message: 'No fue posible encontrar el elemento para marcarlo como favorito.',
        statusCode: 404,
      );
    }

    final updatedItem = _items[index].copyWith(favorite: newFavoriteStatus);
    _items[index] = updatedItem;

    return updatedItem;
  }
}
