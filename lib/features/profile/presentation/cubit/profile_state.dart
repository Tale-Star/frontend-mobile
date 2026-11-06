import 'package:equatable/equatable.dart';
import '../../../authentication/domain/entities/user_entity.dart';

/// Estados de la pantalla de Perfil y Ajustes (Fase 7).
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de la consulta del perfil.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Estado de carga mientras se consulta la información de la cuenta.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Estado exitoso con los datos del usuario autenticado disponibles.
class ProfileLoaded extends ProfileState {
  final UserEntity user;

  const ProfileLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Estado de error ante fallos de conexión o servidor al recuperar el perfil.
class ProfileError extends ProfileState {
  final String message;
  final bool isNetworkError;

  const ProfileError({
    required this.message,
    this.isNetworkError = false,
  });

  @override
  List<Object?> get props => [message, isNetworkError];
}

