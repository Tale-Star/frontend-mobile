import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/exceptions.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/authentication/data/models/user_model.dart';
import 'package:startale_mobile/features/child_mode/data/datasources/parental_pin_remote_datasource.dart';
import 'package:startale_mobile/features/child_mode/data/repositories/parental_pin_repository_impl.dart';

class MockRemoteDataSource extends Mock implements ParentalPinRemoteDataSource {}

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late ParentalPinRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    repository = ParentalPinRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  final tUserModel = UserModel(
    id: 'user-001',
    email: 'tutor@talestar.app',
    displayName: 'Tutor Tale Star',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  group('ParentalPinRepositoryImpl - setParentalPin', () {
    test('retorna UserEntity cuando el datasource responde exitosamente', () async {
      when(() => mockRemoteDataSource.setParentalPin(
            currentPassword: 'password123',
            pin: '1234',
          )).thenAnswer((_) async => tUserModel);

      final result = await repository.setParentalPin(
        currentPassword: 'password123',
        pin: '1234',
      );

      expect(result.id, 'user-001');
      expect(result.pinConfigured, isTrue);
    });

    test('mapea UnauthorizedException a AuthFailure', () async {
      when(() => mockRemoteDataSource.setParentalPin(
            currentPassword: any(named: 'currentPassword'),
            pin: any(named: 'pin'),
          )).thenThrow(const UnauthorizedException(message: 'Contraseña incorrecta'));

      expect(
        () => repository.setParentalPin(currentPassword: 'wrong', pin: '1234'),
        throwsA(isA<AuthFailure>().having((f) => f.message, 'message', 'Contraseña incorrecta')),
      );
    });

    test('mapea NetworkException a NetworkFailure', () async {
      when(() => mockRemoteDataSource.setParentalPin(
            currentPassword: any(named: 'currentPassword'),
            pin: any(named: 'pin'),
          )).thenThrow(const NetworkException(message: 'Sin conexión'));

      expect(
        () => repository.setParentalPin(currentPassword: 'pass', pin: '1234'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('ParentalPinRepositoryImpl - validateParentalPin', () {
    test('retorna true cuando el datasource valida el PIN correctamente', () async {
      when(() => mockRemoteDataSource.validateParentalPin(pin: '1234'))
          .thenAnswer((_) async => true);

      final result = await repository.validateParentalPin(pin: '1234');
      expect(result, isTrue);
    });

    test('retorna false cuando el datasource no valida el PIN', () async {
      when(() => mockRemoteDataSource.validateParentalPin(pin: '0000'))
          .thenAnswer((_) async => false);

      final result = await repository.validateParentalPin(pin: '0000');
      expect(result, isFalse);
    });

    test('mapea NetworkException a NetworkFailure', () async {
      when(() => mockRemoteDataSource.validateParentalPin(pin: any(named: 'pin')))
          .thenThrow(const NetworkException(message: 'Error de red'));

      expect(
        () => repository.validateParentalPin(pin: '1234'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}

