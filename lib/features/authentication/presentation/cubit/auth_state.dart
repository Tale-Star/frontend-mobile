import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Estados reactivos para el flujo de autenticación y sesión en Tale Star.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de verificar sesión.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de procesamiento / carga asíncrona.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado cuando el usuario se encuentra válidamente autenticado.
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Estado cuando no hay ninguna sesión activa o se cerró sesión.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Estado cuando ocurrió un error en login, registro o validación.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado temporal informativo cuando se simula el envío del reseteo de contraseña (US04).
class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

