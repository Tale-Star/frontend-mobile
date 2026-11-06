import '../entities/user_entity.dart';

/// Contrato abstracto del repositorio de autenticación de Tale Star.
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  ///
  /// Conforme a la US03:
  /// - Si [rememberMe] es true: el token JWT se almacena de forma segura en almacenamiento cifrado.
  /// - Si [rememberMe] es false: el token se mantiene exclusivamente en memoria volátil.
  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  /// Registra un nuevo usuario tutor/educador.
  Future<UserEntity> register({
    required String email,
    required String displayName,
    required String password,
    String? parentalPin,
    required bool rememberMe,
  });

  /// Obtiene los datos del usuario autenticado actualmente consultando `/api/v1/auth/me`.
  Future<UserEntity?> getCurrentUser();

  /// Consulta el perfil de usuario directamente a `/api/v1/auth/me` con propagación de fallos tipados.
  Future<UserEntity> getProfile();

  /// Comprueba si existe una sesión válida activa.
  Future<bool> checkAuthStatus();

  /// Cierra la sesión activa y purga tokens y cachés de usuario.
  Future<void> logout();

  /// Flujo asistido/simulado de recuperación de contraseña (US04).
  Future<void> requestPasswordReset({required String email});
}

