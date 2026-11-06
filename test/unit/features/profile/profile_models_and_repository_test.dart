import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:startale_mobile/features/authentication/data/models/user_model.dart';
import 'package:startale_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:startale_mobile/mock/mock_auth_repository.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  group('UserModel Serialization Tests (Fase 7 Contratos)', () {
    test('deserializa correctamente con pin_configured', () {
      final json = {
        'id': 'usr-123',
        'email': 'tutor@talestar.com',
        'display_name': 'Tutor Juan',
        'pin_configured': true,
        'created_at': '2026-10-01T12:00:00Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'usr-123');
      expect(model.email, 'tutor@talestar.com');
      expect(model.displayName, 'Tutor Juan');
      expect(model.pinConfigured, true);
      expect(model.createdAt, DateTime.parse('2026-10-01T12:00:00Z'));
    });

    test('deserializa correctamente con parental_pin_configured oficial de FastAPI', () {
      final json = {
        'id': 'usr-456',
        'email': 'maria@talestar.com',
        'display_name': 'María Docente',
        'parental_pin_configured': true,
        'created_at': '2026-10-15T08:30:00Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'usr-456');
      expect(model.pinConfigured, true);
    });

    test('fallback seguro si flags de pin no están presentes', () {
      final json = {
        'id': 'usr-789',
        'email': 'nuevo@talestar.com',
        'display_name': 'Nuevo Usuario',
        'created_at': '2026-11-01T00:00:00Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.pinConfigured, false);
    });

    test('toJson serializa ambas llaves para compatibilidad total', () {
      final model = UserModel(
        id: 'usr-123',
        email: 'tutor@talestar.com',
        displayName: 'Tutor Juan',
        pinConfigured: true,
        createdAt: DateTime.parse('2026-10-01T12:00:00Z'),
      );

      final json = model.toJson();

      expect(json['pin_configured'], true);
      expect(json['parental_pin_configured'], true);
      expect(json['id'], 'usr-123');
    });
  });

  group('AuthRepository.getProfile Implementation Tests', () {
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockSecureStorageService mockSecureStorageService;
    late MockPreferencesService mockPreferencesService;
    late AuthRepositoryImpl repository;

    final tUserModel = UserModel(
      id: 'usr-real-001',
      email: 'real@talestar.app',
      displayName: 'Papá Andrés',
      pinConfigured: true,
      createdAt: DateTime.parse('2026-10-20T10:00:00Z'),
    );

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

    test('retorna UserEntity y actualiza prefUserId cuando API responde con éxito', () async {
      when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tUserModel);
      when(() => mockPreferencesService.setCurrentUserId(any())).thenAnswer((_) async => true);

      final result = await repository.getProfile();

      expect(result.id, 'usr-real-001');
      expect(result.displayName, 'Papá Andrés');
      verify(() => mockPreferencesService.setCurrentUserId('usr-real-001')).called(1);
    });

    test('mapea UnauthorizedException a AuthFailure y purga sesión', () async {
      when(() => mockRemoteDataSource.getProfile())
          .thenThrow(const UnauthorizedException(message: 'Token expirado.'));
      when(() => mockSecureStorageService.deleteToken()).thenAnswer((_) async {});
      when(() => mockPreferencesService.clearUserSession()).thenAnswer((_) async {});

      expect(() => repository.getProfile(), throwsA(isA<AuthFailure>()));
      await pumpEventQueue();
      verify(() => mockSecureStorageService.deleteToken()).called(1);
    });

    test('mapea NetworkException a NetworkFailure', () async {
      when(() => mockRemoteDataSource.getProfile())
          .thenThrow(const NetworkException(message: 'Sin internet.'));

      expect(() => repository.getProfile(), throwsA(isA<NetworkFailure>()));
    });

    test('mapea ServerException a ServerFailure', () async {
      when(() => mockRemoteDataSource.getProfile())
          .thenThrow(const ServerException(message: 'Error 500', statusCode: 500));

      expect(() => repository.getProfile(), throwsA(isA<ServerFailure>()));
    });
  });

  group('MockAuthRepository.getProfile Tests', () {
    late MockSecureStorageService mockSecureStorageService;
    late MockPreferencesService mockPreferencesService;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockSecureStorageService = MockSecureStorageService();
      mockPreferencesService = MockPreferencesService();
      mockRepo = MockAuthRepository(
        secureStorageService: mockSecureStorageService,
        preferencesService: mockPreferencesService,
      );
    });

    test('retorna el usuario demo cuando el token existe', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => true);

      final user = await mockRepo.getProfile();

      expect(user.displayName, 'Familia Demo');
      expect(user.email, 'demo@talestar.app');
      expect(user.pinConfigured, true);
    });

    test('lanza AuthFailure si no existe token en secure storage', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => false);

      expect(() => mockRepo.getProfile(), throwsA(isA<AuthFailure>()));
    });

    test('simula error_servidor correctamente', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => true);
      mockRepo.simulatedProfileError = true;

      expect(() => mockRepo.getProfile(), throwsA(isA<ServerFailure>()));
    });

    test('permite actualizar el PIN y el usuario en memoria', () async {
      when(() => mockSecureStorageService.hasToken()).thenAnswer((_) async => true);

      mockRepo.updatePinConfigured(false);
      var user = await mockRepo.getProfile();
      expect(user.pinConfigured, false);

      mockRepo.updatePinConfigured(true);
      user = await mockRepo.getProfile();
      expect(user.pinConfigured, true);
    });
  });
}

