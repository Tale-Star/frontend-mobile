import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:startale_mobile/features/authentication/data/models/auth_response_model.dart';
import 'package:startale_mobile/features/authentication/data/models/login_request_model.dart';
import 'package:startale_mobile/features/authentication/data/models/register_request_model.dart';
import 'package:startale_mobile/features/authentication/data/models/user_model.dart';
import 'package:startale_mobile/features/authentication/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockSecureStorageService mockSecureStorageService;
  late MockPreferencesService mockPreferencesService;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const LoginRequestModel(email: '', password: ''));
    registerFallbackValue(const RegisterRequestModel(email: '', displayName: '', password: ''));
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockSecureStorageService = MockSecureStorageService();
    mockPreferencesService = MockPreferencesService();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      secureStorageService: mockSecureStorageService,
      preferencesService: mockPreferencesService,
    );
  });

  final tUserModel = UserModel(
    id: 'user-uuid-1234',
    email: 'tutor@talestar.app',
    displayName: 'Mamá Andrea',
    pinConfigured: false,
    createdAt: DateTime.parse('2026-10-30T10:00:00Z'),
  );

  final tAuthResponse = AuthResponseModel(
    accessToken: 'access_token_jwt_xyz',
    tokenType: 'bearer',
    user: tUserModel,
  );

  group('AuthRepository - login (Estrategia US03)', () {
    test('cuando rememberMe es true, persiste el token y guarda preferencia rememberMe en true', () async {
      when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
      when(() => mockSecureStorageService.saveToken(any(), rememberMe: any(named: 'rememberMe')))
          .thenAnswer((_) async {});
      when(() => mockPreferencesService.setRememberMe(any())).thenAnswer((_) async => true);
      when(() => mockPreferencesService.setCurrentUserId(any())).thenAnswer((_) async => true);

      final result = await repository.login(
        email: 'tutor@talestar.app',
        password: 'Password123!',
        rememberMe: true,
      );

      expect(result.id, 'user-uuid-1234');
      verify(() => mockSecureStorageService.saveToken('access_token_jwt_xyz', rememberMe: true)).called(1);
      verify(() => mockPreferencesService.setRememberMe(true)).called(1);
      verify(() => mockPreferencesService.setCurrentUserId('user-uuid-1234')).called(1);
    });

    test('cuando rememberMe es false, guarda el token como volátil sin persistir en disco', () async {
      when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
      when(() => mockSecureStorageService.saveToken(any(), rememberMe: any(named: 'rememberMe')))
          .thenAnswer((_) async {});
      when(() => mockPreferencesService.setRememberMe(any())).thenAnswer((_) async => true);
      when(() => mockPreferencesService.setCurrentUserId(any())).thenAnswer((_) async => true);

      final result = await repository.login(
        email: 'tutor@talestar.app',
        password: 'Password123!',
        rememberMe: false,
      );

      expect(result.displayName, 'Mamá Andrea');
      verify(() => mockSecureStorageService.saveToken('access_token_jwt_xyz', rememberMe: false)).called(1);
      verify(() => mockPreferencesService.setRememberMe(false)).called(1);
    });

    test('debe traducir UnauthorizedException a AuthFailure', () async {
      when(() => mockRemoteDataSource.login(any())).thenThrow(
        const UnauthorizedException(message: 'Credenciales inválidas'),
      );

      expect(
        () => repository.login(
          email: 'tutor@talestar.app',
          password: 'wrong',
          rememberMe: true,
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('debe traducir NetworkException a NetworkFailure', () async {
      when(() => mockRemoteDataSource.login(any())).thenThrow(
        const NetworkException(message: 'Sin conexión'),
      );

      expect(
        () => repository.login(
          email: 'tutor@talestar.app',
          password: 'pass',
          rememberMe: false,
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('AuthRepository - register', () {
    test('debe registrar el usuario y almacenar credenciales según rememberMe', () async {
      when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => tAuthResponse);
      when(() => mockSecureStorageService.saveToken(any(), rememberMe: any(named: 'rememberMe')))
          .thenAnswer((_) async {});
      when(() => mockPreferencesService.setRememberMe(any())).thenAnswer((_) async => true);
      when(() => mockPreferencesService.setCurrentUserId(any())).thenAnswer((_) async => true);

      final result = await repository.register(
        email: 'tutor@talestar.app',
        displayName: 'Mamá Andrea',
        password: 'Password123!',
        parentalPin: '1234',
        rememberMe: true,
      );

      expect(result.email, 'tutor@talestar.app');
      verify(() => mockSecureStorageService.saveToken('access_token_jwt_xyz', rememberMe: true)).called(1);
    });
  });

  group('AuthRepository - getCurrentUser & logout', () {
    test('getCurrentUser retorna null cuando no existe token previo', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => false);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
      verifyNever(() => mockRemoteDataSource.getProfile());
    });

    test('getCurrentUser retorna el perfil cuando existe token válido', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tUserModel);
      when(() => mockPreferencesService.setCurrentUserId(any())).thenAnswer((_) async => true);

      final result = await repository.getCurrentUser();

      expect(result?.id, 'user-uuid-1234');
      verify(() => mockPreferencesService.setCurrentUserId('user-uuid-1234')).called(1);
    });

    test('logout limpia tokens en almacenamiento seguro y preferencias de sesión', () async {
      when(() => mockSecureStorageService.deleteToken()).thenAnswer((_) async {});
      when(() => mockPreferencesService.clearUserSession()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockSecureStorageService.deleteToken()).called(1);
      verify(() => mockPreferencesService.clearUserSession()).called(1);
    });
  });

  group('AuthRepository - requestPasswordReset (US04)', () {
    test('completa correctamente si el correo es proporcionado', () async {
      await expectLater(
        repository.requestPasswordReset(email: 'tutor@talestar.app'),
        completes,
      );
    });

    test('lanza AuthFailure si el correo está vacío', () async {
      expect(
        () => repository.requestPasswordReset(email: '   '),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}

