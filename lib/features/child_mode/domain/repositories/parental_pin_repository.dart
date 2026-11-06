import '../../../authentication/domain/entities/user_entity.dart';

/// Contrato del repositorio para la administración y validación del PIN parental.
abstract class ParentalPinRepository {
  /// Establece o actualiza el PIN parental del usuario activo.
  ///
  /// Requiere la contraseña actual de la cuenta para validar la identidad del adulto.
  /// Retorna la entidad de usuario actualizada con `pinConfigured: true`.
  Future<UserEntity> setParentalPin({
    required String currentPassword,
    required String pin,
  });

  /// Valida si el PIN ingresado por el adulto es correcto para autorizar la salida de Modo Niño.
  ///
  /// Retorna `true` si el backend valida el PIN exitosamente.
  /// Retorna `false` si el PIN es incorrecto.
  /// Lanza [Failure] ante fallos de red o errores de servidor.
  Future<bool> validateParentalPin({
    required String pin,
  });
}

