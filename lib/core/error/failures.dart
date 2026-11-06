import 'package:equatable/equatable.dart';

/// Fallos de dominio para gestión desacoplada en la capa de presentación.
///
/// Todos los mensajes están redactados con el tono oficial de Tale Star:
/// cercano, claro, constructivo y tranquilizador.
abstract class Failure extends Equatable implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    String message = 'Tuvimos un problema al comunicarnos con el servidor. Inténtalo de nuevo en un momento.',
    this.statusCode,
  }) : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

class AuthFailure extends Failure {
  const AuthFailure({
    String message = 'No pudimos verificar tu cuenta. Revisa tus datos e intenta de nuevo.',
  }) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Parece que no hay conexión a internet. Revisa tu red para continuar explorando.',
  }) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'No se pudo acceder a los datos guardados en el dispositivo.',
  }) : super(message);
}

class PinValidationFailure extends Failure {
  const PinValidationFailure({
    String message = 'El PIN ingresado no coincide. Intenta de nuevo con calma.',
  }) : super(message);
}
