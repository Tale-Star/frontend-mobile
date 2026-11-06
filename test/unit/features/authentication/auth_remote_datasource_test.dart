import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/constants/api_constants.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:startale_mobile/features/authentication/data/models/login_request_model.dart';
import 'package:startale_mobile/features/authentication/data/models/register_request_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio: mockDio);
  });

  const tUserJson = {
    'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'email': 'padre@talestar.app',
    'display_name': 'Papá Ricardo',
    'pin_configured': true,
    'created_at': '2026-10-31T12:00:00Z',
  };

  const tAuthResponseJson = {
    'access_token': 'test_jwt_access_token_123',
    'token_type': 'bearer',
    'user': tUserJson,
  };

  group('AuthRemoteDataSource - login', () {
    const tLoginRequest = LoginRequestModel(
      email: 'padre@talestar.app',
      password: 'SecurePassword123',
    );

    test('debe retornar AuthResponseModel cuando la API responde 200 OK', () async {
      when(() => mockDio.post(
            ApiConstants.login,
            data: tLoginRequest.toJson(),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 200,
          data: tAuthResponseJson,
        ),
      );

      final result = await dataSource.login(tLoginRequest);

      expect(result.accessToken, 'test_jwt_access_token_123');
      expect(result.user.displayName, 'Papá Ricardo');
      expect(result.user.pinConfigured, true);
    });

    test('debe lanzar UnauthorizedException cuando la API responde 401', () async {
      when(() => mockDio.post(
            ApiConstants.login,
            data: tLoginRequest.toJson(),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.login),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.login),
            statusCode: 401,
            data: {'error': {'code': 'invalid_credentials', 'message': 'Invalid credentials'}},
          ),
        ),
      );

      expect(
        () => dataSource.login(tLoginRequest),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('debe lanzar NetworkException cuando ocurre un timeout de conexión', () async {
      when(() => mockDio.post(
            ApiConstants.login,
            data: tLoginRequest.toJson(),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.login),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => dataSource.login(tLoginRequest),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('AuthRemoteDataSource - register', () {
    const tRegisterRequest = RegisterRequestModel(
      email: 'padre@talestar.app',
      displayName: 'Papá Ricardo',
      password: 'SecurePassword123',
      parentalPin: '1234',
    );

    test('debe retornar AuthResponseModel cuando la API responde 201 Created', () async {
      when(() => mockDio.post(
            ApiConstants.register,
            data: tRegisterRequest.toJson(),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.register),
          statusCode: 201,
          data: tAuthResponseJson,
        ),
      );

      final result = await dataSource.register(tRegisterRequest);

      expect(result.accessToken, 'test_jwt_access_token_123');
      expect(result.user.email, 'padre@talestar.app');
    });

    test('debe lanzar ServerException con código 409 cuando el correo ya existe', () async {
      when(() => mockDio.post(
            ApiConstants.register,
            data: tRegisterRequest.toJson(),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.register),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.register),
            statusCode: 409,
            data: {'error': {'code': 'email_already_registered', 'message': 'Email exists'}},
          ),
        ),
      );

      expect(
        () => dataSource.register(tRegisterRequest),
        throwsA(predicate<ServerException>((e) => e.statusCode == 409)),
      );
    });
  });

  group('AuthRemoteDataSource - getProfile', () {
    test('debe retornar UserModel cuando la API responde 200 OK en /me', () async {
      when(() => mockDio.get(ApiConstants.me)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.me),
          statusCode: 200,
          data: tUserJson,
        ),
      );

      final result = await dataSource.getProfile();

      expect(result.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(result.displayName, 'Papá Ricardo');
    });

    test('debe lanzar UnauthorizedException cuando no hay sesión válida (401)', () async {
      when(() => mockDio.get(ApiConstants.me)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.me),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.me),
            statusCode: 401,
          ),
        ),
      );

      expect(
        () => dataSource.getProfile(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}

