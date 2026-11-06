import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startale_mobile/core/config/app_config.dart';
import 'package:startale_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:startale_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:startale_mobile/features/library/data/repositories/library_repository_impl.dart';
import 'package:startale_mobile/features/library/domain/repositories/library_repository.dart';
import 'package:startale_mobile/injection.dart';
import 'package:startale_mobile/mock/mock_auth_repository.dart';
import 'package:startale_mobile/mock/mock_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    AppConfig.reset();
    await resetDependencies();
  });

  group('AppConfig - Seguridad y Delimitación de Mock Mode', () {
    test('en ambiente development con bandera activa, habilita useMockData', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.development,
        overrideUseMockData: true,
      );

      expect(config.environment, AppEnvironment.development);
      expect(config.useMockData, isTrue);
    });

    test('en ambiente staging con bandera activa, PROHÍBE useMockData (evalúa a false)', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.staging,
        overrideUseMockData: true,
      );

      expect(config.environment, AppEnvironment.staging);
      expect(config.useMockData, isFalse);
    });

    test('en ambiente production con bandera activa, PROHÍBE useMockData (evalúa a false)', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.production,
        overrideUseMockData: true,
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.useMockData, isFalse);
    });

    test('en ambiente development con bandera apagada, useMockData permanece false', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.development,
        overrideUseMockData: false,
      );

      expect(config.useMockData, isFalse);
    });
  });

  group('Inyección de Dependencias (Service Locator) - Selección de Repositorios', () {
    test('cuando useMockData es true, inyecta MockAuthRepository y MockLibraryRepository', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await AppConfig.initialize(
        targetEnvironment: AppEnvironment.development,
        overrideUseMockData: true,
      );

      await initDependencies(
        testPrefs: prefs,
      );

      final authRepo = sl<AuthRepository>();
      final libraryRepo = sl<LibraryRepository>();

      expect(authRepo, isA<MockAuthRepository>());
      expect(libraryRepo, isA<MockLibraryRepository>());
      expect(authRepo, isNot(isA<AuthRepositoryImpl>()));
      expect(libraryRepo, isNot(isA<LibraryRepositoryImpl>()));
    });

    test('en producción, NUNCA inyecta repositorios mock, forzando repositorios reales', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Aunque se intente forzar overrideUseMockData en producción, la regla de AppConfig lo prohíbe
      await AppConfig.initialize(
        targetEnvironment: AppEnvironment.production,
        overrideUseMockData: true,
      );

      await initDependencies(
        testPrefs: prefs,
      );

      final authRepo = sl<AuthRepository>();
      final libraryRepo = sl<LibraryRepository>();

      expect(authRepo, isA<AuthRepositoryImpl>());
      expect(libraryRepo, isA<LibraryRepositoryImpl>());
      expect(authRepo, isNot(isA<MockAuthRepository>()));
      expect(libraryRepo, isNot(isA<MockLibraryRepository>()));
    });
  });
}
