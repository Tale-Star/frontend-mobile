import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/config/app_config.dart';

void main() {
  setUp(() {
    AppConfig.reset();
  });

  tearDown(() {
    AppConfig.reset();
  });

  group('AppConfig AR Decoupling & Security', () {
    test('por defecto useMockAr es false y useMockData es false', () {
      final config = AppConfig.instance;
      expect(config.useMockAr, isFalse);
      expect(config.useMockData, isFalse);
      expect(config.environment, equals(AppEnvironment.development));
    });

    test('permite activar useMockData sin activar useMockAr (Contenido simulado + ARCore real)', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.development,
        overrideUseMockData: true,
        overrideUseMockAr: false,
      );

      expect(config.useMockData, isTrue);
      expect(config.useMockAr, isFalse);
    });

    test('permite activar useMockAr independientemente en desarrollo', () async {
      final config = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.development,
        overrideUseMockData: false,
        overrideUseMockAr: true,
      );

      expect(config.useMockData, isFalse);
      expect(config.useMockAr, isTrue);
    });

    test('en ambiente de producción o staging, useMockAr y useMockData siempre son false por seguridad', () async {
      final prodConfig = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.production,
        overrideUseMockData: true,
        overrideUseMockAr: true,
      );

      expect(prodConfig.useMockData, isFalse);
      expect(prodConfig.useMockAr, isFalse);

      final stagingConfig = await AppConfig.initialize(
        targetEnvironment: AppEnvironment.staging,
        overrideUseMockData: true,
        overrideUseMockAr: true,
      );

      expect(stagingConfig.useMockData, isFalse);
      expect(stagingConfig.useMockAr, isFalse);
    });
  });
}

