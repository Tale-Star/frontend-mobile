import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';
import 'package:startale_mobile/features/reader/domain/repositories/reader_repository.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_cubit.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_state.dart';

class MockReaderRepository extends Mock implements ReaderRepository {}

void main() {
  late MockReaderRepository mockRepository;
  late ReaderCubit cubit;

  setUp(() {
    mockRepository = MockReaderRepository();
    cubit = ReaderCubit(readerRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  const tStoryId = 'story-123';

  final tStory = StoryDetail(
    id: tStoryId,
    title: 'El Pequeño Astronauta',
    description: 'Aventura estelar.',
    createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
  );

  final tPages = [
    StoryPageDetail(
      id: 'p-1',
      storyId: tStoryId,
      pageNumber: 1,
      action: 'Mirando el cielo',
      text: 'Había una vez un pequeño astronauta.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    ),
    StoryPageDetail(
      id: 'p-2',
      storyId: tStoryId,
      pageNumber: 2,
      action: 'En la nave',
      text: 'Despegó rumbo a la luna.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
    ),
    StoryPageDetail(
      id: 'p-3',
      storyId: tStoryId,
      pageNumber: 3,
      action: 'Llegada',
      text: 'Y plantó su bandera de estrellas.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:02:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:02:00.000Z'),
    ),
  ];

  test('estado inicial es ReaderInitial', () {
    expect(cubit.state, equals(const ReaderInitial()));
  });

  group('ReaderCubit - loadStory', () {
    blocTest<ReaderCubit, ReaderState>(
      'emite [ReaderLoading, ReaderLoaded] cuando el cuento y sus páginas cargan correctamente',
      build: () {
        when(() => mockRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
        when(() => mockRepository.getStoryPages(tStoryId)).thenAnswer((_) async => tPages);
        return cubit;
      },
      act: (c) => c.loadStory(tStoryId),
      expect: () => [
        const ReaderLoading(),
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      ],
      verify: (_) {
        verify(() => mockRepository.getStory(tStoryId)).called(1);
        verify(() => mockRepository.getStoryPages(tStoryId)).called(1);
      },
    );

    blocTest<ReaderCubit, ReaderState>(
      'emite [ReaderLoading, ReaderEmpty] cuando el cuento no contiene ninguna página',
      build: () {
        when(() => mockRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
        when(() => mockRepository.getStoryPages(tStoryId)).thenAnswer((_) async => const []);
        return cubit;
      },
      act: (c) => c.loadStory(tStoryId),
      expect: () => [
        const ReaderLoading(),
        ReaderEmpty(story: tStory),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'emite [ReaderLoading, ReaderError] cuando falla getStory',
      build: () {
        when(() => mockRepository.getStory(tStoryId))
            .thenThrow(const ServerFailure(message: 'Cuento no encontrado'));
        when(() => mockRepository.getStoryPages(tStoryId)).thenAnswer((_) async => tPages);
        return cubit;
      },
      act: (c) => c.loadStory(tStoryId),
      expect: () => [
        const ReaderLoading(),
        const ReaderError(message: 'Cuento no encontrado'),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'emite [ReaderLoading, ReaderError] cuando falla getStoryPages',
      build: () {
        when(() => mockRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
        when(() => mockRepository.getStoryPages(tStoryId))
            .thenThrow(const NetworkFailure(message: 'Error de red'));
        return cubit;
      },
      act: (c) => c.loadStory(tStoryId),
      expect: () => [
        const ReaderLoading(),
        const ReaderError(message: 'Error de red'),
      ],
    );
  });

  group('ReaderCubit - Navegación de páginas', () {
    blocTest<ReaderCubit, ReaderState>(
      'nextPage incrementa currentPageIndex si hasNextPage es true',
      build: () {
        when(() => mockRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
        when(() => mockRepository.getStoryPages(tStoryId)).thenAnswer((_) async => tPages);
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      act: (c) => c.nextPage(),
      expect: () => [
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 1),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'nextPage no emite nuevo estado ni incrementa más allá de la última página',
      build: () {
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 2),
      act: (c) => c.nextPage(),
      expect: () => [],
    );

    blocTest<ReaderCubit, ReaderState>(
      'previousPage decrementa currentPageIndex si hasPreviousPage es true',
      build: () {
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 2),
      act: (c) => c.previousPage(),
      expect: () => [
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 1),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'previousPage no emite nuevo estado si ya está en la primera página',
      build: () {
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      act: (c) => c.previousPage(),
      expect: () => [],
    );

    blocTest<ReaderCubit, ReaderState>(
      'goToPage navega a un índice válido',
      build: () {
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      act: (c) => c.goToPage(2),
      expect: () => [
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 2),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'goToPage ignora índices fuera de rango',
      build: () {
        return cubit;
      },
      seed: () => ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      act: (c) {
        c.goToPage(-1);
        c.goToPage(5);
        c.goToPage(0); // Mismo índice actual
      },
      expect: () => [],
    );
  });

  group('ReaderCubit - retry', () {
    blocTest<ReaderCubit, ReaderState>(
      'retry vuelve a cargar el cuento previo tras un fallo',
      build: () {
        when(() => mockRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
        when(() => mockRepository.getStoryPages(tStoryId)).thenAnswer((_) async => tPages);
        return cubit;
      },
      act: (c) async {
        await c.loadStory(tStoryId);
        await c.retry();
      },
      expect: () => [
        const ReaderLoading(),
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
        const ReaderLoading(),
        ReaderLoaded(story: tStory, pages: tPages, currentPageIndex: 0),
      ],
    );
  });
}
