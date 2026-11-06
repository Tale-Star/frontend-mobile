import 'dart:convert';
import '../../core/error/failures.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../features/authentication/domain/entities/user_entity.dart';
import '../features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'mock_auth_repository.dart';

/// Implementación simulada de [ParentalPinRepository] para desarrollo y pruebas manuales (Mock Mode).
///
/// Permite probar el ciclo de vida completo de Modo Niño (configuración de PIN, validación,
/// bloqueo y persistencia) en hardware real Android sin depender del despliegue del backend FastAPI.
///
/// Regla de seguridad: Nunca almacena el PIN en texto plano ni utiliza contraseñas reales.
class MockParentalPinRepository implements ParentalPinRepository {
  final SecureStorageService secureStorageService;
  final PreferencesService preferencesService;
  final MockAuthRepository? mockAuthRepository;

  static const String defaultMockPin = '1234';

  // Almacén en memoria volátil
  String _currentPinHash = _hashPin(defaultMockPin);
  bool _pinConfigured = true;

  MockParentalPinRepository({
    required this.secureStorageService,
    required this.preferencesService,
    this.mockAuthRepository,
    bool initialPinConfigured = true,
  }) : _pinConfigured = initialPinConfigured;

  static String _hashPin(String pin) {
    // Hash salado determinista con dart:convert para pruebas seguras sin persistir texto plano
    final bytes = utf8.encode('ts_salt_mock_pin_$pin');
    return base64Encode(bytes);
  }

  /// Permite a las pruebas restablecer o configurar el PIN simulado directamente.
  void setSimulatedPin(String pin) {
    _currentPinHash = _hashPin(pin);
    _pinConfigured = true;
  }

  /// Permite a las pruebas alternar si el usuario simulado tiene PIN configurado.
  void setPinConfigured(bool configured) {
    _pinConfigured = configured;
  }

  bool get isPinConfigured => _pinConfigured;

  @override
  Future<UserEntity> setParentalPin({
    required String currentPassword,
    required String pin,
  }) async {
    // Simula latencia de red realista
    await Future.delayed(const Duration(milliseconds: 300));

    // Simulación de escenarios de error mediante palabras clave
    if (currentPassword == 'error_red' || pin == '9991') {
      throw const NetworkFailure(
        message: 'No se pudo conectar con el servidor para guardar tu PIN.',
      );
    }

    if (currentPassword == 'error_servidor' || pin == '9992') {
      throw const ServerFailure(
        message: 'El servicio de seguridad no está disponible temporalmente.',
        statusCode: 500,
      );
    }

    if (currentPassword == 'wrong_password' || currentPassword == 'invalido') {
      throw const AuthFailure(
        message: 'La contraseña actual ingresada es incorrecta. Por favor verifícala.',
      );
    }

    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw const PinValidationFailure(
        message: 'El PIN debe contener exactamente 4 dígitos numéricos.',
      );
    }

    _currentPinHash = _hashPin(pin);
    _pinConfigured = true;

    // Actualiza el usuario simulado en MockAuthRepository si está disponible
    final user = await mockAuthRepository?.getCurrentUser() ??
        MockAuthRepository.defaultDemoUser;

    return user.copyWith(pinConfigured: true);
  }

  @override
  Future<bool> validateParentalPin({required String pin}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (pin == '9991') {
      throw const NetworkFailure(
        message: 'No pudimos conectar con el servidor para validar el PIN. El modo protegido continúa activo.',
      );
    }

    if (pin == '9992') {
      throw const ServerFailure(
        message: 'Error temporal en el servicio de validación de PIN.',
        statusCode: 500,
      );
    }

    if (pin.length != 4 || int.tryParse(pin) == null) {
      return false;
    }

    final inputHash = _hashPin(pin);
    final isValid = inputHash == _currentPinHash;
    return isValid;
  }
}
