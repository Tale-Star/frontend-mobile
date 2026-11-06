import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/library/data/datasources/library_remote_datasource.dart';
import 'package:startale_mobile/features/library/data/models/library_item_model.dart';
import 'package:startale_mobile/features/library/data/repositories/library_repository_impl.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';

class MockLibraryRemoteDataSource extends Mock implements LibraryRemoteDataSource {}

void main() {
  late MockLibraryRemoteDataSource mockDataSource;
  late LibraryRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockLibraryRemoteDataSource();
    repository = LibraryRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final tModel1 = LibraryItemModel(
    id: 'item-uuid-1',
    type: ContentType.story,
    resourceId: 'story-uuid-1',
    name: 'El Árbol Sabio',
    description: 'Un cuento sobre la naturaleza y la amistad.',
    favorite: false,
    resourceUrl: '/api/v1/stories/story-uuid-1',
    mediaType: null,
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  final tModel2 = LibraryItemModel(
    id: 'item-uuid-2',
    type: ContentType.image,
    resourceId: 'image-uuid-2',
    name: 'Bosque Mágico',
    description: 'Ilustración digital de un bosque con hadas.',
    favorite: true,
    resourceUrl: '/api/v1/media/assets/image-uuid-2',
    mediaType: 'image/png',
    createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T11:00:00Z'),
  );

  group('LibraryRepository - getLibraryItems', () {
    test('retorna lista de entidades cuando el datasource responde exitosamente', () async {
      when(() => mockDataSource.getLibraryItems(
            type: any(named: 'type'),
            q: any(named: 'q'),
            favorite: any(named: 'favorite'),
          )).thenAnswer((_) async => [tModel1, tModel2]);

      final result = await repository.getLibraryItems();

      expect(result.length, 2);
      expect(result[0].id, 'item-uuid-1');
      expect(result[0].type, ContentType.story);
      expect(result[1].id, 'item-uuid-2');
      expect(result[1].type, ContentType.image);
    });

    test('envía los parámetros de tipo, búsqueda y favorito al datasource', () async {
      when(() => mockDataSource.getLibraryItems(
            type: 'story',
            q: 'Árbol',
            favorite: true,
          )).thenAnswer((_) async => [tModel1]);

      final result = await repository.getLibraryItems(
        type: ContentType.story,
        query: 'Árbol',
        favorite: true,
      );

      expect(result.length, 1);
      expect(result.first.name, 'El Árbol Sabio');
      verify(() => mockDataSource.getLibraryItems(
            type: 'story',
            q: 'Árbol',
            favorite: true,
          )).called(1);
    });

    test('lanza AuthFailure cuando el datasource lanza UnauthorizedException', () async {
      when(() => mockDataSource.getLibraryItems(
            type: any(named: 'type'),
            q: any(named: 'q'),
            favorite: any(named: 'favorite'),
          )).thenThrow(const UnauthorizedException(message: 'Sesión expirada'));

      expect(
        () => repository.getLibraryItems(),
        throwsA(isA<AuthFailure>().having((f) => f.message, 'message', 'Sesión expirada')),
      );
    });

    test('lanza NetworkFailure cuando el datasource lanza NetworkException', () async {
      when(() => mockDataSource.getLibraryItems(
            type: any(named: 'type'),
            q: any(named: 'q'),
            favorite: any(named: 'favorite'),
          )).thenThrow(const NetworkException(message: 'Sin internet'));

      expect(
        () => repository.getLibraryItems(),
        throwsA(isA<NetworkFailure>().having((f) => f.message, 'message', 'Sin internet')),
      );
    });

    test('lanza ServerFailure cuando el datasource lanza ServerException', () async {
      when(() => mockDataSource.getLibraryItems(
            type: any(named: 'type'),
            q: any(named: 'q'),
            favorite: any(named: 'favorite'),
          )).thenThrow(const ServerException(message: 'Error interno', statusCode: 500));

      expect(
        () => repository.getLibraryItems(),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('LibraryRepository - getLibraryItem', () {
    test('retorna la entidad correspondiente por su id', () async {
      when(() => mockDataSource.getLibraryItem('item-uuid-1'))
          .thenAnswer((_) async => tModel1);

      final result = await repository.getLibraryItem('item-uuid-1');

      expect(result.id, 'item-uuid-1');
      expect(result.name, 'El Árbol Sabio');
    });

    test('lanza AuthFailure ante UnauthorizedException', () async {
      when(() => mockDataSource.getLibraryItem(any()))
          .thenThrow(const UnauthorizedException(message: 'No autorizado'));

      expect(
        () => repository.getLibraryItem('item-uuid-1'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('lanza ServerFailure ante ServerException', () async {
      when(() => mockDataSource.getLibraryItem(any()))
          .thenThrow(const ServerException(message: 'No encontrado', statusCode: 404));

      expect(
        () => repository.getLibraryItem('item-uuid-1'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('LibraryRepository - toggleFavorite', () {
    test('retorna el elemento con el estado de favorito actualizado', () async {
      final updatedModel = LibraryItemModel.fromEntity(tModel1.copyWith(favorite: true));
      when(() => mockDataSource.patchLibraryItem('item-uuid-1', favorite: true))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.toggleFavorite('item-uuid-1', true);

      expect(result.favorite, true);
      verify(() => mockDataSource.patchLibraryItem('item-uuid-1', favorite: true)).called(1);
    });

    test('lanza NetworkFailure ante fallas de red al actualizar favorito', () async {
      when(() => mockDataSource.patchLibraryItem(any(), favorite: any(named: 'favorite')))
          .thenThrow(const NetworkException(message: 'Error de conexión'));

      expect(
        () => repository.toggleFavorite('item-uuid-1', true),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('lanza ServerFailure ante fallas del servidor al actualizar favorito', () async {
      when(() => mockDataSource.patchLibraryItem(any(), favorite: any(named: 'favorite')))
          .thenThrow(const ServerException(message: 'Error en base de datos'));

      expect(
        () => repository.toggleFavorite('item-uuid-1', true),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
