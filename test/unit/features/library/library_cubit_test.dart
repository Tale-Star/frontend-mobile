import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/constants/app_constants.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/features/library/domain/repositories/library_repository.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_cubit.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_state.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late MockLibraryRepository mockRepository;
  late LibraryCubit cubit;

  setUp(() {
    mockRepository = MockLibraryRepository();
    cubit = LibraryCubit(libraryRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  final tItem1 = LibraryItemEntity(
    id: 'item-uuid-1',
    type: ContentType.story,
    resourceId: 'story-uuid-1',
    name: 'El Árbol Sabio',
    description: 'Un cuento sobre la naturaleza.',
    favorite: false,
    resourceUrl: '/api/v1/stories/story-uuid-1',
    mediaType: null,
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  final tItem2 = LibraryItemEntity(
    id: 'item-uuid-2',
    type: ContentType.image,
    resourceId: 'image-uuid-2',
    name: 'Castillo en las Estrellas',
    description: 'Ilustración infantil.',
    favorite: true,
    resourceUrl: '/api/v1/media/assets/image-uuid-2',
    mediaType: 'image/png',
    createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T11:00:00Z'),
  );

  test('estado inicial debe ser LibraryInitial', () {
    expect(cubit.state, equals(const LibraryInitial()));
  });

  group('loadLibrary', () {
    blocTest<LibraryCubit, LibraryState>(
      'emite [LibraryLoading, LibraryLoaded] cuando el repositorio retorna elementos',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: any(named: 'query'),
              favorite: any(named: 'favorite'),
            )).thenAnswer((_) async => [tItem1, tItem2]);
        return cubit;
      },
      act: (c) => c.loadLibrary(),
      expect: () => [
        const LibraryLoading(),
        LibraryLoaded(items: [tItem1, tItem2]),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'emite [LibraryLoading, LibraryEmpty] cuando la lista devuelta está vacía',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: any(named: 'query'),
              favorite: any(named: 'favorite'),
            )).thenAnswer((_) async => []);
        return cubit;
      },
      act: (c) => c.loadLibrary(),
      expect: () => [
        const LibraryLoading(),
        const LibraryEmpty(),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'emite [LibraryLoading, LibraryError] cuando el repositorio lanza un Failure',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: any(named: 'query'),
              favorite: any(named: 'favorite'),
            )).thenThrow(const ServerFailure(message: 'Error de servidor'));
        return cubit;
      },
      act: (c) => c.loadLibrary(),
      expect: () => [
        const LibraryLoading(),
        const LibraryError(message: 'Error de servidor'),
      ],
    );
  });

  group('Filtros y Búsqueda', () {
    blocTest<LibraryCubit, LibraryState>(
      'setTypeFilter actualiza el filtro activo y recarga',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: ContentType.story,
              query: any(named: 'query'),
              favorite: any(named: 'favorite'),
            )).thenAnswer((_) async => [tItem1]);
        return cubit;
      },
      act: (c) => c.setTypeFilter(ContentType.story),
      expect: () => [
        const LibraryLoading(activeFilter: ContentType.story),
        LibraryLoaded(items: [tItem1], activeFilter: ContentType.story),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'setTypeFilter no hace nada si el filtro solicitado ya está activo',
      seed: () => LibraryLoaded(items: [tItem1], activeFilter: ContentType.story),
      build: () => cubit,
      act: (c) => c.setTypeFilter(ContentType.story),
      expect: () => [],
    );

    blocTest<LibraryCubit, LibraryState>(
      'setFavoriteOnly activa la bandera favoriteOnly y recarga',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: any(named: 'query'),
              favorite: true,
            )).thenAnswer((_) async => [tItem2]);
        return cubit;
      },
      act: (c) => c.setFavoriteOnly(true),
      expect: () => [
        const LibraryLoading(favoriteOnly: true),
        LibraryLoaded(items: [tItem2], favoriteOnly: true),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'searchImmediate ejecuta búsqueda inmediata con el query especificado',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: 'Castillo',
              favorite: any(named: 'favorite'),
            )).thenAnswer((_) async => [tItem2]);
        return cubit;
      },
      act: (c) => c.searchImmediate('Castillo'),
      expect: () => [
        const LibraryLoading(searchQuery: 'Castillo'),
        LibraryLoaded(items: [tItem2], searchQuery: 'Castillo'),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'onSearchChanged aplica debounce de 400ms antes de llamar al repositorio',
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: any(named: 'type'),
              query: 'Castillo',
              favorite: any(named: 'favorite'),
            )).thenAnswer((_) async => [tItem2]);
        return cubit;
      },
      act: (c) {
        c.onSearchChanged('Cas');
        c.onSearchChanged('Castillo');
      },
      wait: AppConstants.searchDebounce + const Duration(milliseconds: 100),
      expect: () => [
        const LibraryLoading(searchQuery: 'Castillo'),
        LibraryLoaded(items: [tItem2], searchQuery: 'Castillo'),
      ],
    );
  });

  group('toggleFavorite', () {
    final tItem1Favorited = tItem1.copyWith(favorite: true);

    blocTest<LibraryCubit, LibraryState>(
      'actualiza el elemento en la lista tras un PATCH exitoso',
      seed: () => LibraryLoaded(items: [tItem1, tItem2]),
      build: () {
        when(() => mockRepository.toggleFavorite('item-uuid-1', true))
            .thenAnswer((_) async => tItem1Favorited);
        return cubit;
      },
      act: (c) => c.toggleFavorite(tItem1),
      expect: () => [
        LibraryLoaded(items: [tItem1, tItem2], togglingFavoriteId: 'item-uuid-1'),
        LibraryLoaded(items: [tItem1Favorited, tItem2], togglingFavoriteId: null),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'remueve el elemento si favoriteOnly es true y se desmarca de favorito',
      seed: () => LibraryLoaded(items: [tItem2], favoriteOnly: true),
      build: () {
        final tItem2Unfavorited = tItem2.copyWith(favorite: false);
        when(() => mockRepository.toggleFavorite('item-uuid-2', false))
            .thenAnswer((_) async => tItem2Unfavorited);
        return cubit;
      },
      act: (c) => c.toggleFavorite(tItem2),
      expect: () => [
        LibraryLoaded(items: [tItem2], favoriteOnly: true, togglingFavoriteId: 'item-uuid-2'),
        const LibraryEmpty(favoriteOnly: true),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'emite LibraryError y revierte estado de carga si la petición falla',
      seed: () => LibraryLoaded(items: [tItem1]),
      build: () {
        when(() => mockRepository.toggleFavorite('item-uuid-1', true))
            .thenThrow(const NetworkFailure(message: 'Error de conexión'));
        return cubit;
      },
      act: (c) => c.toggleFavorite(tItem1),
      expect: () => [
        LibraryLoaded(items: [tItem1], togglingFavoriteId: 'item-uuid-1'),
        LibraryError(message: 'Error de conexión', previousItems: [tItem1]),
        LibraryLoaded(items: [tItem1], togglingFavoriteId: null),
      ],
    );
  });

  group('refresh', () {
    blocTest<LibraryCubit, LibraryState>(
      'recarga la biblioteca conservando los filtros activos',
      seed: () => LibraryLoaded(
        items: [tItem1],
        activeFilter: ContentType.story,
        searchQuery: 'sabio',
      ),
      build: () {
        when(() => mockRepository.getLibraryItems(
              type: ContentType.story,
              query: 'sabio',
              favorite: null,
            )).thenAnswer((_) async => [tItem1]);
        return cubit;
      },
      act: (c) => c.refresh(),
      expect: () => [
        const LibraryLoading(activeFilter: ContentType.story, searchQuery: 'sabio'),
        LibraryLoaded(
          items: [tItem1],
          activeFilter: ContentType.story,
          searchQuery: 'sabio',
        ),
      ],
    );
  });
}

