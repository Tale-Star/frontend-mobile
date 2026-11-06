import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/reader/data/datasources/reader_remote_datasource.dart';
import 'package:startale_mobile/features/reader/data/models/story_page_model.dart';
import 'package:startale_mobile/features/reader/data/models/story_response_model.dart';
import 'package:startale_mobile/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';

class MockReaderRemoteDataSource extends Mock implements ReaderRemoteDataSource {}

void main() {
  late MockReaderRemoteDataSource mockDataSource;
  late ReaderRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockReaderRemoteDataSource();
    repository = ReaderRepositoryImpl(remoteDataSource: mockDataSource);
  });

  const tStoryId = 'story-123';

  final tStoryModel = StoryResponseModel(
    id: tStoryId,
    title: 'La Aventura de Luna',
    description: 'Un cuento sobre la curiosidad.',
    scenarioId: 'scen-1',
    styleProfileId: 'style-1',
    seed: 99,
    createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T11:00:00.000Z'),
  );

  final tUnsortedPageModels = [
    StoryPageModel(
      id: 'page-3',
      storyId: tStoryId,
      pageNumber: 3,
      action: 'Página final.',
      text: 'Y colorín colorado este cuento se ha acabado.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:02:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:02:00.000Z'),
    ),
    StoryPageModel(
      id: 'page-1',
      storyId: tStoryId,
      pageNumber: 1,
      action: 'Inicio.',
      text: 'Había una vez en una noche estrellada...',
      characterIds: const ['luna'],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    ),
    StoryPageModel(
      id: 'page-2',
      storyId: tStoryId,
      pageNumber: 2,
      action: 'Desarrollo.',
      text: 'Luna encontró una pequeña estrella perdida.',
      characterIds: const ['luna', 'estrella'],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
      updatedAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
    ),
  ];

  group('ReaderRepository - getStory', () {
    test('retorna StoryDetail cuando el datasource responde con éxito', () async {
      when(() => mockDataSource.getStory(tStoryId)).thenAnswer((_) async => tStoryModel);

      final result = await repository.getStory(tStoryId);

      expect(result, isA<StoryDetail>());
      expect(result.id, tStoryId);
      expect(result.title, 'La Aventura de Luna');
      verify(() => mockDataSource.getStory(tStoryId)).called(1);
    });

    test('lanza ServerFailure cuando el datasource lanza ServerException', () async {
      when(() => mockDataSource.getStory(tStoryId))
          .thenThrow(const ServerException(message: 'Error en servidor', statusCode: 500));

      expect(
        () => repository.getStory(tStoryId),
        throwsA(isA<ServerFailure>().having((f) => f.message, 'message', 'Error en servidor')),
      );
    });

    test('lanza NetworkFailure cuando el datasource lanza NetworkException', () async {
      when(() => mockDataSource.getStory(tStoryId))
          .thenThrow(const NetworkException(message: 'Sin conexión a internet'));

      expect(
        () => repository.getStory(tStoryId),
        throwsA(isA<NetworkFailure>().having((f) => f.message, 'message', 'Sin conexión a internet')),
      );
    });
  });

  group('ReaderRepository - getStoryPages', () {
    test('retorna páginas estrictamente ordenadas por pageNumber ascendente', () async {
      when(() => mockDataSource.getStoryPages(tStoryId)).thenAnswer((_) async => tUnsortedPageModels);

      final pages = await repository.getStoryPages(tStoryId);

      expect(pages.length, 3);
      expect(pages[0].pageNumber, 1);
      expect(pages[0].text, contains('Había una vez'));
      expect(pages[1].pageNumber, 2);
      expect(pages[1].text, contains('Luna encontró'));
      expect(pages[2].pageNumber, 3);
      expect(pages[2].text, contains('colorín colorado'));
    });

    test('retorna lista vacía cuando el cuento no tiene páginas creadas', () async {
      when(() => mockDataSource.getStoryPages(tStoryId)).thenAnswer((_) async => []);

      final pages = await repository.getStoryPages(tStoryId);

      expect(pages, isEmpty);
    });

    test('lanza ServerFailure cuando falla la obtención de páginas', () async {
      when(() => mockDataSource.getStoryPages(tStoryId))
          .thenThrow(const ServerException(message: 'Cuento no encontrado', statusCode: 404));

      expect(
        () => repository.getStoryPages(tStoryId),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
