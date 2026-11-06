import '../../core/error/failures.dart';
import '../../core/storage/authenticated_cache.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../features/authentication/domain/entities/user_entity.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';

/// Implementación simulada de [AuthRepository] exclusivamente para desarrollo y pruebas manuales (Mock Mode).
///
/// Proporciona un usuario de demostración ficticio sin requerir credenciales reales,
/// backend desplegado ni tokens JWT auténticos.
class MockAuthRepository implements AuthRepository {
  final SecureStorageService secureStorageService;
  final PreferencesService preferencesService;

  static const String mockToken = 'mock_demo_session_token_xyz_123';

  static final UserEntity defaultDemoUser = UserEntity(
    id: 'mock-user-demo-001',
    email: 'demo@talestar.app',
    displayName: 'Familia Demo',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  UserEntity _currentUser = defaultDemoUser;

  MockAuthRepository({
    required this.secureStorageService,
    required this.preferencesService,
  });

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    // Simulación de latencia de red realista
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.toLowerCase().trim();

    // Permite simular fallos mediante palabras clave para verificar mensajes en la UI
    if (normalizedEmail.contains('error_red') || password == 'error_red') {
      throw const NetworkFailure(
        message: 'No pudimos conectar con el servidor de Tale Star. Revisa tu conexión a internet.',
      );
    }
    if (normalizedEmail.contains('error_servidor') || password == 'error_servidor') {
      throw const ServerFailure(
        message: 'El servicio de autenticación no está disponible en este momento.',
        statusCode: 500,
      );
    }
    if (normalizedEmail.contains('invalido') || password == 'invalido') {
      throw const AuthFailure(
        message: 'Correo o contraseña incorrectos. Verifica tus datos.',
      );
    }

    _currentUser = defaultDemoUser.copyWith(
      email: normalizedEmail.isNotEmpty ? normalizedEmail : defaultDemoUser.email,
    );

    // Persistencia simulada respetando US03
    await secureStorageService.saveToken(mockToken, rememberMe: rememberMe);
    await preferencesService.setRememberMe(rememberMe);
    await preferencesService.setCurrentUserId(_currentUser.id);

    return _currentUser;
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String displayName,
    required String password,
    String? parentalPin,
    required bool rememberMe,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.toLowerCase().trim();

    if (normalizedEmail.contains('error_red')) {
      throw const NetworkFailure(
        message: 'No se pudo completar el registro por un problema de conexión.',
      );
    }

    _currentUser = UserEntity(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Tutor Tale Star',
      pinConfigured: parentalPin != null && parentalPin.isNotEmpty,
      createdAt: DateTime.now(),
    );

    await secureStorageService.saveToken(mockToken, rememberMe: rememberMe);
    await preferencesService.setRememberMe(rememberMe);
    await preferencesService.setCurrentUserId(_currentUser.id);

    return _currentUser;
  }

  bool simulatedProfileError = false;

  @override
  Future<UserEntity?> getCurrentUser() async {
    final hasToken = await secureStorageService.hasToken();
    if (!hasToken) return null;
    return _currentUser;
  }

  @override
  Future<UserEntity> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final hasToken = await secureStorageService.hasToken();
    if (!hasToken) {
      throw const AuthFailure(message: 'Sesión no iniciada.');
    }
    if (simulatedProfileError || _currentUser.email.contains('error_servidor')) {
      throw const ServerFailure(
        message: 'El servicio de perfil no está disponible en este momento.',
        statusCode: 500,
      );
    }
    if (_currentUser.email.contains('error_red')) {
      throw const NetworkFailure(
        message: 'No pudimos conectar con el servidor de Tale Star. Revisa tu conexión a internet.',
      );
    }
    return _currentUser;
  }

  /// Permite actualizar el usuario en memoria para pruebas o cambio de PIN.
  void setDemoUser(UserEntity user) {
    _currentUser = user;
  }

  /// Actualiza reactivamente el estado del PIN en memoria.
  void updatePinConfigured(bool pinConfigured) {
    _currentUser = _currentUser.copyWith(pinConfigured: pinConfigured);
  }

  @override
  Future<bool> checkAuthStatus() async {
    return secureStorageService.hasToken();
  }

  @override
  Future<void> logout() async {
    await secureStorageService.deleteToken();
    await preferencesService.clearUserSession();
    await AuthenticatedCacheManager.clearAllCaches();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulación completada (US04 - Excepción de alcance aceptada)
  }
}
