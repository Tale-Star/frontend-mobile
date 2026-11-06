import 'package:equatable/equatable.dart';
import '../../domain/entities/child_mode_content.dart';

/// Jerarquía de estados del Modo Niño (Fase 6).
abstract class ChildModeState extends Equatable {
  const ChildModeState();

  @override
  List<Object?> get props => [];
}

/// Estado inactivo: La aplicación opera en el contexto estándar de adulto.
class ChildModeInactive extends ChildModeState {
  const ChildModeInactive();
}

/// Estado de transición mientras se prepara o confirma la activación.
class ChildModeActivating extends ChildModeState {
  final ChildModeContent targetContent;

  const ChildModeActivating({required this.targetContent});

  @override
  List<Object?> get props => [targetContent];
}

/// Estado activo: La aplicación está confinada en el consumo del recurso protegido.
class ChildModeActive extends ChildModeState {
  final ChildModeContent content;
  final String userId;

  const ChildModeActive({
    required this.content,
    required this.userId,
  });

  @override
  List<Object?> get props => [content, userId];
}

/// Estado de solicitud de desbloqueo: El adulto está ingresando el PIN parental.
class ChildModeUnlocking extends ChildModeState {
  final ChildModeContent content;
  final String userId;
  final bool isValidating;

  const ChildModeUnlocking({
    required this.content,
    required this.userId,
    this.isValidating = false,
  });

  @override
  List<Object?> get props => [content, userId, isValidating];
}

/// Estado de error en la validación del PIN o bloqueo temporal.
class ChildModeValidationError extends ChildModeState {
  final ChildModeContent content;
  final String userId;
  final String errorMessage;
  final int failedAttempts;
  final int attemptsRemaining;
  final bool isLockedOut;
  final int lockoutSecondsRemaining;

  const ChildModeValidationError({
    required this.content,
    required this.userId,
    required this.errorMessage,
    required this.failedAttempts,
    required this.attemptsRemaining,
    this.isLockedOut = false,
    this.lockoutSecondsRemaining = 0,
  });

  @override
  List<Object?> get props => [
        content,
        userId,
        errorMessage,
        failedAttempts,
        attemptsRemaining,
        isLockedOut,
        lockoutSecondsRemaining,
      ];
}

/// Estado de restauración: Recuperando el estado activo desde el almacenamiento local persistente.
class ChildModeRestoring extends ChildModeState {
  const ChildModeRestoring();
}

