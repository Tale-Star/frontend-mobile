import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/constants/app_constants.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
    service = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService (Estrategia US03)', () {
    test('cuando rememberMe es false, el token se guarda solo en memoria volátil', () async {
      when(() => mockStorage.delete(key: AppConstants.secureKeyAccessToken))
          .thenAnswer((_) async {});

      await service.saveToken('token_volatil', rememberMe: false);

      // Verificamos que se borró de storage persistido
      verify(() => mockStorage.delete(key: AppConstants.secureKeyAccessToken)).called(1);
      verifyNever(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));

      // Pero sigue disponible en memoria durante la sesión
      final token = await service.getToken();
      expect(token, 'token_volatil');
      expect(await service.hasToken(), isTrue);
    });

    test('cuando rememberMe es true, el token se persiste en el almacenamiento seguro', () async {
      when(() => mockStorage.write(
            key: AppConstants.secureKeyAccessToken,
            value: 'token_persistido',
          )).thenAnswer((_) async {});

      await service.saveToken('token_persistido', rememberMe: true);

      verify(() => mockStorage.write(
            key: AppConstants.secureKeyAccessToken,
            value: 'token_persistido',
          )).called(1);

      final token = await service.getToken();
      expect(token, 'token_persistido');
    });

    test('deleteToken elimina el token tanto de memoria como de storage seguro', () async {
      when(() => mockStorage.delete(key: AppConstants.secureKeyAccessToken))
          .thenAnswer((_) async {});

      await service.saveToken('token_para_borrar', rememberMe: false);
      expect(await service.hasToken(), isTrue);

      await service.deleteToken();
      expect(await service.getToken(), isNull);
      expect(await service.hasToken(), isFalse);
    });

    test('getToken recupera del storage si no está en memoria volátil (reinicio con rememberMe)', () async {
      when(() => mockStorage.read(key: AppConstants.secureKeyAccessToken))
          .thenAnswer((_) async => 'token_recuperado_de_storage');

      final freshService = SecureStorageService(storage: mockStorage);
      final token = await freshService.getToken();

      expect(token, 'token_recuperado_de_storage');
      verify(() => mockStorage.read(key: AppConstants.secureKeyAccessToken)).called(1);
    });
  });
}
