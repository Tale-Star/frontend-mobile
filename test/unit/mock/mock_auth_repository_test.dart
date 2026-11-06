import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/mock/mock_auth_repository.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService mockSecureStorage;
  late MockPreferencesService mockPreferences;
  late MockAuthRepository repository;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    mockPreferences = MockPreferencesService();
    repository = MockAuthRepository(
      secureStorageService: mockSecureStorage,
      preferencesService: mockPreferences,
    );

    when(() => mockSecureStorage.saveToken(any(), rememberMe: any(named: 'rememberMe')))
        .thenAnswer((_) async {});
    when(() => mockPreferences.setRememberMe(any())).thenAnswer((_) async => true);
    when(() => mockPreferences.setCurrentUserId(any())).thenAnswer((_) async => true);
    when(() => mockSecureStorage.deleteToken()).thenAnswer((_) async {});
    when(() => mockPreferences.clearUserSession()).thenAnswer((_) async {});
  });

  group('MockAuthRepository - login', () {
    test('inicia sesión exitosamente con credenciales demo ficticias', () async {
      final user = await repository.login(
        email: 'demo@talestar.app',
        password: 'password123',
        rememberMe: true,
      );

      expect(user.displayName, 'Familia Demo');
      expect(user.email, 'demo@talestar.app');
      expect(user.pinConfigured, isTrue);

      verify(() => mockSecureStorage.saveToken(MockAuthRepository.mockToken, rememberMe: true)).called(1);
      verify(() => mockPreferences.setRememberMe(true)).called(1);
      verify(() => mockPreferences.setCurrentUserId(user.id)).called(1);
    });

    test('simula NetworkFailure cuando el correo contiene error_red', () async {
      expect(
        () => repository.login(
          email: 'usuario_error_red@demo.com',
          password: 'cualquiera',
          rememberMe: false,
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('simula ServerFailure cuando el correo contiene error_servidor', () async {
      expect(
        () => repository.login(
          email: 'usuario_error_servidor@demo.com',
          password: 'cualquiera',
          rememberMe: false,
        ),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('simula AuthFailure cuando el correo contiene invalido', () async {
      expect(
        () => repository.login(
          email: 'invalido@demo.com',
          password: 'cualquiera',
          rememberMe: false,
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('MockAuthRepository - register', () {
    test('registra un usuario ficticio con los datos ingresados', () async {
      final user = await repository.register(
        email: 'nuevo_tutor@talestar.app',
        displayName: 'Papá Santiago',
        password: 'password123',
        rememberMe: false,
      );

      expect(user.displayName, 'Papá Santiago');
      expect(user.email, 'nuevo_tutor@talestar.app');
      verify(() => mockSecureStorage.saveToken(MockAuthRepository.mockToken, rememberMe: false)).called(1);
    });

    test('simula NetworkFailure ante error_red en registro', () async {
      expect(
        () => repository.register(
          email: 'error_red@demo.com',
          displayName: 'Demo',
          password: 'password123',
          rememberMe: false,
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('MockAuthRepository - sesión y estado', () {
    test('getCurrentUser retorna usuario si hasToken es true', () async {
      when(() => mockSecureStorage.hasToken()).thenAnswer((_) async => true);

      final user = await repository.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.displayName, 'Familia Demo');
    });

    test('getCurrentUser retorna null si hasToken es false', () async {
      when(() => mockSecureStorage.hasToken()).thenAnswer((_) async => false);

      final user = await repository.getCurrentUser();

      expect(user, isNull);
    });

    test('logout purga credenciales en secure storage y preferencias', () async {
      await repository.logout();

      verify(() => mockSecureStorage.deleteToken()).called(1);
      verify(() => mockPreferences.clearUserSession()).called(1);
    });
  });
}
