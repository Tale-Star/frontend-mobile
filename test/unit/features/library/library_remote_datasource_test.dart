import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/constants/api_constants.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/features/library/data/datasources/library_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late LibraryRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = LibraryRemoteDataSourceImpl(dio: mockDio);
  });

  const tItemJson = {
    'id': 'item-uuid-1',
    'type': 'story',
    'resource_id': 'story-uuid-1',
    'name': 'La Pequeña Estrella',
    'description': 'Un cuento sobre la curiosidad y el valor.',
    'favorite': true,
    'resource_url': '/api/v1/stories/story-uuid-1',
    'media_type': null,
    'created_at': '2026-10-31T12:00:00Z',
    'updated_at': '2026-10-31T12:00:00Z',
  };

  group('LibraryRemoteDataSource - getLibraryItems', () {
    test('retorna lista de LibraryItemModel cuando el backend responde 200 OK', () async {
      when(() => mockDio.get(
            ApiConstants.library,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.library),
          statusCode: 200,
          data: [tItemJson],
        ),
      );

      final result = await dataSource.getLibraryItems();

      expect(result.length, 1);
      expect(result.first.name, 'La Pequeña Estrella');
      expect(result.first.isStory, true);
    });

    test('envía correctamente los parámetros de filtrado type, q y favorite', () async {
      when(() => mockDio.get(
            ApiConstants.library,
            queryParameters: {
              'type': 'image',
              'q': 'estrellas',
              'favorite': true,
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.library),
          statusCode: 200,
          data: [tItemJson],
        ),
      );

      final result = await dataSource.getLibraryItems(
        type: 'image',
        q: 'estrellas',
        favorite: true,
      );

      expect(result.length, 1);
      verify(() => mockDio.get(
            ApiConstants.library,
            queryParameters: {
              'type': 'image',
              'q': 'estrellas',
              'favorite': true,
            },
          )).called(1);
    });

    test('lanza UnauthorizedException cuando el backend responde 401', () async {
      when(() => mockDio.get(
            ApiConstants.library,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.library),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.library),
            statusCode: 401,
          ),
        ),
      );

      expect(
        () => dataSource.getLibraryItems(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('lanza ServerException con código 422 cuando los parámetros son inválidos', () async {
      when(() => mockDio.get(
            ApiConstants.library,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.library),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.library),
            statusCode: 422,
            data: {'error': {'message': 'Parámetros no permitidos'}},
          ),
        ),
      );

      expect(
        () => dataSource.getLibraryItems(),
        throwsA(predicate<ServerException>((e) => e.statusCode == 422)),
      );
    });

    test('lanza NetworkException ante fallos de conectividad o timeouts', () async {
      when(() => mockDio.get(
            ApiConstants.library,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.library),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => dataSource.getLibraryItems(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('LibraryRemoteDataSource - getLibraryItem & patchLibraryItem', () {
    test('getLibraryItem retorna elemento cuando responde 200 OK', () async {
      when(() => mockDio.get(ApiConstants.libraryItem('item-uuid-1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.libraryItem('item-uuid-1')),
          statusCode: 200,
          data: tItemJson,
        ),
      );

      final result = await dataSource.getLibraryItem('item-uuid-1');

      expect(result.id, 'item-uuid-1');
      expect(result.name, 'La Pequeña Estrella');
    });

    test('getLibraryItem lanza ServerException con código 404 si no existe', () async {
      when(() => mockDio.get(ApiConstants.libraryItem('not-found'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.libraryItem('not-found')),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.libraryItem('not-found')),
            statusCode: 404,
          ),
        ),
      );

      expect(
        () => dataSource.getLibraryItem('not-found'),
        throwsA(predicate<ServerException>((e) => e.statusCode == 404)),
      );
    });

    test('patchLibraryItem envía favorite y retorna el modelo actualizado', () async {
      final updatedJson = Map<String, dynamic>.from(tItemJson)..['favorite'] = false;

      when(() => mockDio.patch(
            ApiConstants.libraryItem('item-uuid-1'),
            data: {'favorite': false},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.libraryItem('item-uuid-1')),
          statusCode: 200,
          data: updatedJson,
        ),
      );

      final result = await dataSource.patchLibraryItem('item-uuid-1', favorite: false);

      expect(result.favorite, false);
      verify(() => mockDio.patch(
            ApiConstants.libraryItem('item-uuid-1'),
            data: {'favorite': false},
          )).called(1);
    });
  });
}

