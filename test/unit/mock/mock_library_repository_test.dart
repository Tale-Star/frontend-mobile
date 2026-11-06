import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/mock/mock_library_repository.dart';

void main() {
  late MockLibraryRepository repository;

  setUp(() {
    repository = MockLibraryRepository();
  });

  group('MockLibraryRepository - getLibraryItems', () {
    test('retorna los 10 elementos de fixtures iniciales sin filtros', () async {
      final items = await repository.getLibraryItems();

      expect(items.length, 10);
      expect(items.where((i) => i.isImage).length, 4);
      expect(items.where((i) => i.isStory).length, 3);
      expect(items.where((i) => i.isMusic).length, 3);
    });

    test('filtra correctamente por ContentType.image', () async {
      final items = await repository.getLibraryItems(type: ContentType.image);

      expect(items.length, 4);
      expect(items.every((i) => i.isImage), isTrue);
    });

    test('filtra correctamente por ContentType.story', () async {
      final items = await repository.getLibraryItems(type: ContentType.story);

      expect(items.length, 3);
      expect(items.every((i) => i.isStory), isTrue);
    });

    test('filtra correctamente por ContentType.music', () async {
      final items = await repository.getLibraryItems(type: ContentType.music);

      expect(items.length, 3);
      expect(items.every((i) => i.isMusic), isTrue);
    });

    test('filtra por favoritos (favorite == true)', () async {
      final items = await repository.getLibraryItems(favorite: true);

      expect(items.isNotEmpty, isTrue);
      expect(items.every((i) => i.favorite), isTrue);
    });

    test('busca por coincidencia de texto en nombre o descripción', () async {
      final items = await repository.getLibraryItems(query: 'Luciérnagas');

      expect(items.length, 1);
      expect(items.first.name, 'El Bosque de las Luciérnagas');
    });

    test('simula NetworkFailure cuando la búsqueda incluye error_red', () async {
      expect(
        () => repository.getLibraryItems(query: 'error_red'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('simula ServerFailure cuando la búsqueda incluye error_servidor', () async {
      expect(
        () => repository.getLibraryItems(query: 'error_servidor'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('simula respuesta vacía cuando la búsqueda incluye vacio', () async {
      final items = await repository.getLibraryItems(query: 'vacio');

      expect(items, isEmpty);
    });

    test('simula NetworkFailure cuando la bandera simulateNetworkError está activa', () async {
      repository.simulateNetworkError = true;

      expect(
        () => repository.getLibraryItems(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('simula respuesta vacía cuando simulateEmptyResponse está activa', () async {
      repository.simulateEmptyResponse = true;

      final items = await repository.getLibraryItems();

      expect(items, isEmpty);
    });
  });

  group('MockLibraryRepository - getLibraryItem y toggleFavorite', () {
    test('getLibraryItem retorna el elemento correspondiente por id', () async {
      final item = await repository.getLibraryItem('img-demo-001');

      expect(item.id, 'img-demo-001');
      expect(item.name, 'El Bosque de las Luciérnagas');
    });

    test('getLibraryItem lanza ServerFailure 404 si el id no existe', () async {
      expect(
        () => repository.getLibraryItem('inexistente-123'),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404)),
      );
    });

    test('toggleFavorite altera el estado en memoria y persiste para consultas posteriores', () async {
      final initialItem = await repository.getLibraryItem('img-demo-002');
      expect(initialItem.favorite, isFalse);

      final updated = await repository.toggleFavorite('img-demo-002', true);
      expect(updated.favorite, isTrue);

      final queriedAgain = await repository.getLibraryItem('img-demo-002');
      expect(queriedAgain.favorite, isTrue);
    });
  });
}

