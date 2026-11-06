import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/mock/mock_parental_pin_repository.dart';

class MockSecureStorage extends Mock implements SecureStorageService {}
class MockPreferences extends Mock implements PreferencesService {}

void main() {
  late MockParentalPinRepository mockRepo;
  late MockSecureStorage mockSecureStorage;
  late MockPreferences mockPreferences;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockPreferences = MockPreferences();
    mockRepo = MockParentalPinRepository(
      secureStorageService: mockSecureStorage,
      preferencesService: mockPreferences,
    );
  });

  group('MockParentalPinRepository Tests', () {
    test('valida por defecto el PIN 1234', () async {
      final isValid = await mockRepo.validateParentalPin(pin: '1234');
      final isWrong = await mockRepo.validateParentalPin(pin: '0000');

      expect(isValid, isTrue);
      expect(isWrong, isFalse);
    });

    test('permite actualizar el PIN y validar el nuevo valor', () async {
      final user = await mockRepo.setParentalPin(
        currentPassword: 'password123',
        pin: '9876',
      );

      expect(user.pinConfigured, isTrue);

      final isOldValid = await mockRepo.validateParentalPin(pin: '1234');
      final isNewValid = await mockRepo.validateParentalPin(pin: '9876');

      expect(isOldValid, isFalse);
      expect(isNewValid, isTrue);
    });

    test('simula error_red lanzando NetworkFailure', () async {
      expect(
        () => mockRepo.setParentalPin(currentPassword: 'error_red', pin: '1234'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(
        () => mockRepo.validateParentalPin(pin: '9991'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('simula error_servidor lanzando ServerFailure', () async {
      expect(
        () => mockRepo.setParentalPin(currentPassword: 'error_servidor', pin: '1234'),
        throwsA(isA<ServerFailure>()),
      );
      expect(
        () => mockRepo.validateParentalPin(pin: '9992'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('simula wrong_password lanzando AuthFailure', () async {
      expect(
        () => mockRepo.setParentalPin(currentPassword: 'wrong_password', pin: '1234'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('rechaza PIN con longitud diferente a 4 dígitos', () async {
      expect(
        () => mockRepo.setParentalPin(currentPassword: 'password', pin: '123'),
        throwsA(isA<PinValidationFailure>()),
      );

      final isValidShort = await mockRepo.validateParentalPin(pin: '12');
      expect(isValidShort, isFalse);
    });
  });
}

