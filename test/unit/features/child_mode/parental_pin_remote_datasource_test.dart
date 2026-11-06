import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/constants/api_constants.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/features/child_mode/data/datasources/parental_pin_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ParentalPinRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ParentalPinRemoteDataSourceImpl(dio: mockDio);
  });

  const tUserJson = {
    'id': 'user-1234-uuid',
    'email': 'padre@talestar.app',
    'display_name': 'Papá Ricardo',
    'pin_configured': true,
    'created_at': '2026-10-31T12:00:00Z',
  };

  group('ParentalPinRemoteDataSource - setParentalPin', () {
    test('debe retornar UserModel con pin_configured true cuando la API responde 200 OK', () async {
      when(() => mockDio.put(
            ApiConstants.parentalPin,
            data: {'current_password': 'MyPassword123', 'pin': '1234'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.parentalPin),
          statusCode: 200,
          data: tUserJson,
        ),
      );

      final result = await dataSource.setParentalPin(
        currentPassword: 'MyPassword123',
        pin: '1234',
      );

      expect(result.id, 'user-1234-uuid');
      expect(result.pinConfigured, isTrue);
    });

    test('debe lanzar UnauthorizedException cuando la contraseña actual es incorrecta (401)', () async {
      when(() => mockDio.put(
            ApiConstants.parentalPin,
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.parentalPin),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.parentalPin),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.setParentalPin(currentPassword: 'wrong', pin: '1234'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('debe lanzar ServerException cuando el formato de PIN no es de 4 dígitos (422)', () async {
      when(() => mockDio.put(
            ApiConstants.parentalPin,
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.parentalPin),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.parentalPin),
            statusCode: 422,
            data: {
              'error': {'message': 'El PIN debe contener 4 dígitos'}
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.setParentalPin(currentPassword: 'pass', pin: '12'),
        throwsA(isA<ServerException>()),
      );
    });

    test('debe lanzar NetworkException ante timeout de red', () async {
      when(() => mockDio.put(
            ApiConstants.parentalPin,
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.parentalPin),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => dataSource.setParentalPin(currentPassword: 'pass', pin: '1234'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ParentalPinRemoteDataSource - validateParentalPin', () {
    test('debe retornar true cuando la API responde { valid: true }', () async {
      when(() => mockDio.post(
            ApiConstants.validateParentalPin,
            data: {'pin': '1234'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.validateParentalPin),
          statusCode: 200,
          data: {'valid': true},
        ),
      );

      final result = await dataSource.validateParentalPin(pin: '1234');
      expect(result, isTrue);
    });

    test('debe retornar false cuando la API responde { valid: false }', () async {
      when(() => mockDio.post(
            ApiConstants.validateParentalPin,
            data: {'pin': '9999'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.validateParentalPin),
          statusCode: 200,
          data: {'valid': false},
        ),
      );

      final result = await dataSource.validateParentalPin(pin: '9999');
      expect(result, isFalse);
    });

    test('debe lanzar NetworkException ante fallo de conexión sin dar por validado el PIN', () async {
      when(() => mockDio.post(
            ApiConstants.validateParentalPin,
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.validateParentalPin),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.validateParentalPin(pin: '1234'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

