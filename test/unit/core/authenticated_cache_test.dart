import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/authenticated_cache.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService mockSecureStorage;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_windows'),
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
  });

  tearDown(() async {
    await AuthenticatedCacheManager.clearAllCaches();
  });

  group('AuthenticatedCacheManager - resolveUrl', () {
    test('retorna cadena vacía si resourceUrl es nulo o vacío', () {
      expect(AuthenticatedCacheManager.resolveUrl(null), '');
      expect(AuthenticatedCacheManager.resolveUrl(''), '');
      expect(AuthenticatedCacheManager.resolveUrl('   '), '');
    });

    test('retorna la URL tal cual si ya es absoluta (http o https)', () {
      const httpsUrl = 'https://cdn.talestar.app/images/sample.png';
      const httpUrl = 'http://localhost:8000/media/sample.png';

      expect(AuthenticatedCacheManager.resolveUrl(httpsUrl), httpsUrl);
      expect(AuthenticatedCacheManager.resolveUrl(httpUrl), httpUrl);
    });

    test('concatena correctamente rutas relativas con customBaseUrl', () {
      const customBase = 'https://api.talestar.com';
      expect(
        AuthenticatedCacheManager.resolveUrl(
          '/api/v1/media/assets/uuid-123',
          customBaseUrl: customBase,
        ),
        'https://api.talestar.com/api/v1/media/assets/uuid-123',
      );

      // Si la base tiene barra final y el path no tiene inicial
      expect(
        AuthenticatedCacheManager.resolveUrl(
          'api/v1/media/assets/uuid-123',
          customBaseUrl: 'https://api.talestar.com/',
        ),
        'https://api.talestar.com/api/v1/media/assets/uuid-123',
      );
    });
  });

  group('AuthenticatedCacheManager - getAuthHeaders', () {
    test('retorna Authorization con Bearer token cuando el token existe', () async {
      when(() => mockSecureStorage.getToken()).thenAnswer((_) async => 'jwt_secret_token_abc');

      final headers = await AuthenticatedCacheManager.getAuthHeaders(mockSecureStorage);

      expect(headers, {'Authorization': 'Bearer jwt_secret_token_abc'});
    });

    test('retorna mapa vacío cuando no hay token almacenado', () async {
      when(() => mockSecureStorage.getToken()).thenAnswer((_) async => null);

      final headers = await AuthenticatedCacheManager.getAuthHeaders(mockSecureStorage);

      expect(headers, isEmpty);
    });

    test('retorna mapa vacío cuando el token es una cadena en blanco', () async {
      when(() => mockSecureStorage.getToken()).thenAnswer((_) async => '   ');

      final headers = await AuthenticatedCacheManager.getAuthHeaders(mockSecureStorage);

      expect(headers, isEmpty);
    });
  });

  group('AuthenticatedCacheManager - Aislamiento de caché multi-usuario', () {
    test('forUser retorna instancias independientes por cada usuario', () {
      final cacheUserA = AuthenticatedCacheManager.forUser(
        userId: 'user_alpha',
        secureStorageService: mockSecureStorage,
      );

      final cacheUserB = AuthenticatedCacheManager.forUser(
        userId: 'user_beta',
        secureStorageService: mockSecureStorage,
      );

      expect(cacheUserA.userId, 'user_alpha');
      expect(cacheUserB.userId, 'user_beta');
      expect(cacheUserA, isNot(same(cacheUserB)));
    });

    test('forUser reutiliza la misma instancia para el mismo usuario', () {
      final cache1 = AuthenticatedCacheManager.forUser(
        userId: 'user_gamma',
        secureStorageService: mockSecureStorage,
      );

      final cache2 = AuthenticatedCacheManager.forUser(
        userId: 'user_gamma',
        secureStorageService: mockSecureStorage,
      );

      expect(cache1, same(cache2));
    });

    test('clearUserCache elimina la instancia activa del usuario', () async {
      final cache = AuthenticatedCacheManager.forUser(
        userId: 'user_to_clear',
        secureStorageService: mockSecureStorage,
      );

      await AuthenticatedCacheManager.clearUserCache('user_to_clear');

      final newCache = AuthenticatedCacheManager.forUser(
        userId: 'user_to_clear',
        secureStorageService: mockSecureStorage,
      );

      // Una nueva instancia debe haber sido creada
      expect(newCache, isNot(same(cache)));
    });

    test('clearAllCaches vacía todas las instancias registradas', () async {
      final cache1 = AuthenticatedCacheManager.forUser(
        userId: 'user_1',
        secureStorageService: mockSecureStorage,
      );

      await AuthenticatedCacheManager.clearAllCaches();

      final newCache1 = AuthenticatedCacheManager.forUser(
        userId: 'user_1',
        secureStorageService: mockSecureStorage,
      );

      expect(newCache1, isNot(same(cache1)));
    });
  });
}
