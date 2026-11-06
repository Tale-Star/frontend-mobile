import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/features/reader/data/datasources/reader_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ReaderRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ReaderRemoteDataSourceImpl(dio: mockDio);
  });

  const tStoryId = 'story-uuid-123';
  const tStoryPath = '/api/v1/stories/story-uuid-123';
  const tPagesPath = '/api/v1/stories/story-uuid-123/pages';

  final tStoryJson = {
    'id': tStoryId,
    'title': 'El Pequeño Astronauta',
    'description': 'Aventura en el espacio exterior.',
    'scenario_id': 'scen-1',
    'style_profile_id': 'style-1',
    'seed': 42,
    'created_at': '2026-10-31T10:00:00.000Z',
    'updated_at': '2026-10-31T11:00:00.000Z',
  };

  final tPagesJson = [
    {
      'id': 'page-1',
      'story_id': tStoryId,
      'page_number': 1,
      'action': 'Leo sube a la nave.',
      'text': 'Leo se puso su traje espacial.',
      'visual_config': {'view': 'close-up'},
      'character_ids': ['char-1'],
      'seed': 100,
      'created_at': '2026-10-31T10:00:00.000Z',
      'updated_at': '2026-10-31T10:05:00.000Z',
    },
    {
      'id': 'page-2',
      'story_id': tStoryId,
      'page_number': 2,
      'action': 'Despegue!',
      'text': '3, 2, 1... Despegue!',
      'visual_config': null,
      'character_ids': [],
      'seed': null,
      'created_at': '2026-10-31T10:00:00.000Z',
      'updated_at': null,
    },
  ];

  group('ReaderRemoteDataSource - getStory', () {
    test('retorna StoryResponseModel cuando la respuesta es 200 OK', () async {
      when(() => mockDio.get(tStoryPath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: tStoryPath),
          statusCode: 200,
          data: tStoryJson,
        ),
      );

      final result = await dataSource.getStory(tStoryId);

      expect(result.id, tStoryId);
      expect(result.title, 'El Pequeño Astronauta');
      expect(result.description, 'Aventura en el espacio exterior.');
    });

    test('lanza UnauthorizedException cuando responde 401 Unauthorized', () async {
      when(() => mockDio.get(tStoryPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tStoryPath),
          response: Response(
            requestOptions: RequestOptions(path: tStoryPath),
            statusCode: 401,
            data: {'detail': 'Could not validate credentials'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.getStory(tStoryId),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('lanza ServerException cuando responde 404 Not Found', () async {
      when(() => mockDio.get(tStoryPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tStoryPath),
          response: Response(
            requestOptions: RequestOptions(path: tStoryPath),
            statusCode: 404,
            data: {'detail': 'Story not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.getStory(tStoryId),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('lanza NetworkException ante error de conexión o timeout', () async {
      when(() => mockDio.get(tStoryPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tStoryPath),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => dataSource.getStory(tStoryId),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ReaderRemoteDataSource - getStoryPages', () {
    test('retorna lista de StoryPageModel cuando responde 200 OK', () async {
      when(() => mockDio.get(tPagesPath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: tPagesPath),
          statusCode: 200,
          data: tPagesJson,
        ),
      );

      final result = await dataSource.getStoryPages(tStoryId);

      expect(result.length, 2);
      expect(result.first.pageNumber, 1);
      expect(result.first.text, 'Leo se puso su traje espacial.');
      expect(result.last.pageNumber, 2);
    });

    test('retorna lista vacía sin error cuando el cuento no tiene páginas', () async {
      when(() => mockDio.get(tPagesPath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: tPagesPath),
          statusCode: 200,
          data: [],
        ),
      );

      final result = await dataSource.getStoryPages(tStoryId);

      expect(result, isEmpty);
    });

    test('lanza ServerException ante 404 Not Found en páginas', () async {
      when(() => mockDio.get(tPagesPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tPagesPath),
          response: Response(
            requestOptions: RequestOptions(path: tPagesPath),
            statusCode: 404,
            data: {'detail': 'Story not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.getStoryPages(tStoryId),
        throwsA(isA<ServerException>()),
      );
    });

    test('lanza NetworkException ante desconexión de red', () async {
      when(() => mockDio.get(tPagesPath)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: tPagesPath),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.getStoryPages(tStoryId),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

