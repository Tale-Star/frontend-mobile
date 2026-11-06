import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../domain/entities/child_mode_content.dart';
import '../../domain/repositories/parental_pin_repository.dart';
import 'child_mode_state.dart';

/// Cubit central que administra el confinamiento de Modo Niño y la validación de PIN parental (Fase 6).
class ChildModeCubit extends Cubit<ChildModeState> {
  final ParentalPinRepository parentalPinRepository;
  final PreferencesService preferencesService;
  final AuthCubit authCubit;

  int _failedAttempts = 0;
  Timer? _lockoutTimer;
  int _lockoutSecondsRemaining = 0;

  ChildModeCubit({
    required this.parentalPinRepository,
    required this.preferencesService,
    required this.authCubit,
  }) : super(const ChildModeInactive());

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _lockoutSecondsRemaining > 0;
  int get lockoutSecondsRemaining => _lockoutSecondsRemaining;

  /// Restaura la sesión de Modo Niño si estaba activa antes de cerrar la app.
  Future<void> restoreSession() async {
    if (!preferencesService.isChildModeActive) {
      emit(const ChildModeInactive());
      return;
    }

    emit(const ChildModeRestoring());

    final contentTypeStr = preferencesService.childModeContentType;
    final contentId = preferencesService.childModeContentId;
    final title = preferencesService.childModeContentTitle;
    final routeContext = preferencesService.childModeRouteContext;
    final userId = preferencesService.childModeUserId;

    if (contentTypeStr != null &&
        contentId != null &&
        title != null &&
        routeContext != null &&
        userId != null) {
      final content = ChildModeContent(
        contentType: ChildModeContentTypeX.fromValue(contentTypeStr),
        contentId: contentId,
        title: title,
        routeContext: routeContext,
        activatedAt: DateTime.now(),
      );

      emit(ChildModeActive(content: content, userId: userId));
    } else {
      // Datos incompletos o corruptos: limpia la sesión por seguridad
      await preferencesService.clearChildModeSession();
      emit(const ChildModeInactive());
    }
  }

  /// Activa el Modo Niño sobre un recurso previamente seleccionado por el adulto.
  ///
  /// Valida que el usuario esté autenticado y disponga de un PIN parental configurado.
  Future<bool> activate({
    required ChildModeContentType contentType,
    required String contentId,
    required String contentTitle,
    required String routeContext,
  }) async {
    final authState = authCubit.state;
    if (authState is! Authenticated) {
      return false;
    }

    final user = authState.user;
    if (!user.pinConfigured) {
      return false;
    }

    final content = ChildModeContent(
      contentType: contentType,
      contentId: contentId,
      title: contentTitle,
      routeContext: routeContext,
      activatedAt: DateTime.now(),
    );

    emit(ChildModeActivating(targetContent: content));

    // Persistencia para recuperación ante reinicio
    await preferencesService.saveChildModeSession(
      contentType: contentType.toValue(),
      contentId: contentId,
      title: contentTitle,
      routeContext: routeContext,
      userId: user.id,
    );

    _failedAttempts = 0;
    _cancelLockoutTimer();

    emit(ChildModeActive(content: content, userId: user.id));
    return true;
  }

  /// Solicita salir de Modo Niño, iniciando el flujo de validación de PIN.
  void requestExit() {
    final current = state;
    if (current is ChildModeActive) {
      emit(ChildModeUnlocking(
        content: current.content,
        userId: current.userId,
      ));
    } else if (current is ChildModeValidationError) {
      emit(ChildModeUnlocking(
        content: current.content,
        userId: current.userId,
      ));
    }
  }

  /// Cancela la solicitud de salida y regresa al contenido protegido.
  void cancelExit() {
    final current = state;
    if (current is ChildModeUnlocking) {
      emit(ChildModeActive(
        content: current.content,
        userId: current.userId,
      ));
    } else if (current is ChildModeValidationError) {
      emit(ChildModeActive(
        content: current.content,
        userId: current.userId,
      ));
    }
  }

  /// Valida el PIN parental ante el servidor. Si es válido, desactiva el modo protegido.
  ///
  /// Retorna `true` únicamente cuando el servidor certifica `valid == true`.
  Future<bool> validatePinAndExit(String pin) async {
    final current = state;
    ChildModeContent? activeContent;
    String? currentUserId;

    if (current is ChildModeUnlocking) {
      activeContent = current.content;
      currentUserId = current.userId;
    } else if (current is ChildModeValidationError) {
      activeContent = current.content;
      currentUserId = current.userId;
    } else if (current is ChildModeActive) {
      activeContent = current.content;
      currentUserId = current.userId;
    }

    if (activeContent == null || currentUserId == null) {
      return false;
    }

    // Comprobación de bloqueo temporal por intentos fallidos
    if (isLockedOut) {
      emit(ChildModeValidationError(
        content: activeContent,
        userId: currentUserId,
        errorMessage: 'Demasiados intentos fallidos. Espera $_lockoutSecondsRemaining segundos.',
        failedAttempts: _failedAttempts,
        attemptsRemaining: 0,
        isLockedOut: true,
        lockoutSecondsRemaining: _lockoutSecondsRemaining,
      ));
      return false;
    }

    emit(ChildModeUnlocking(
      content: activeContent,
      userId: currentUserId,
      isValidating: true,
    ));

    try {
      final isValid = await parentalPinRepository.validateParentalPin(pin: pin);

      if (isValid) {
        // Desbloqueo exitoso confirmado por el servidor
        _failedAttempts = 0;
        _cancelLockoutTimer();
        await preferencesService.clearChildModeSession();
        emit(const ChildModeInactive());
        return true;
      } else {
        // PIN incorrecto
        _failedAttempts++;
        final remaining = (AppConstants.maxFailedPinAttempts - _failedAttempts).clamp(0, AppConstants.maxFailedPinAttempts);

        if (_failedAttempts >= AppConstants.maxFailedPinAttempts) {
          _startLockout(activeContent, currentUserId);
        } else {
          emit(ChildModeValidationError(
            content: activeContent,
            userId: currentUserId,
            errorMessage: 'El PIN ingresado es incorrecto. Intentos restantes: $remaining',
            failedAttempts: _failedAttempts,
            attemptsRemaining: remaining,
          ));
        }
        return false;
      }
    } on Failure catch (failure) {
      // Cualquier fallo de red o servidor MANTIENE el modo protegido activo
      emit(ChildModeValidationError(
        content: activeContent,
        userId: currentUserId,
        errorMessage: failure.message,
        failedAttempts: _failedAttempts,
        attemptsRemaining: (AppConstants.maxFailedPinAttempts - _failedAttempts).clamp(0, AppConstants.maxFailedPinAttempts),
      ));
      return false;
    } catch (_) {
      emit(ChildModeValidationError(
        content: activeContent,
        userId: currentUserId,
        errorMessage: 'No fue posible validar el PIN. El modo protegido continúa activo.',
        failedAttempts: _failedAttempts,
        attemptsRemaining: (AppConstants.maxFailedPinAttempts - _failedAttempts).clamp(0, AppConstants.maxFailedPinAttempts),
      ));
      return false;
    }
  }

  void _startLockout(ChildModeContent content, String userId) {
    _lockoutSecondsRemaining = AppConstants.pinLockoutDuration.inSeconds;
    emit(ChildModeValidationError(
      content: content,
      userId: userId,
      errorMessage: 'Has superado el límite de intentos. Por seguridad, espera 30 segundos.',
      failedAttempts: _failedAttempts,
      attemptsRemaining: 0,
      isLockedOut: true,
      lockoutSecondsRemaining: _lockoutSecondsRemaining,
    ));

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lockoutSecondsRemaining--;
      if (_lockoutSecondsRemaining <= 0) {
        timer.cancel();
        _lockoutSecondsRemaining = 0;
        _failedAttempts = 0;
        if (state is ChildModeValidationError) {
          emit(ChildModeUnlocking(content: content, userId: userId));
        }
      } else {
        if (state is ChildModeValidationError) {
          emit(ChildModeValidationError(
            content: content,
            userId: userId,
            errorMessage: 'Espera $_lockoutSecondsRemaining segundos para volver a intentar.',
            failedAttempts: _failedAttempts,
            attemptsRemaining: 0,
            isLockedOut: true,
            lockoutSecondsRemaining: _lockoutSecondsRemaining,
          ));
        }
      }
    });
  }

  void _cancelLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    _lockoutSecondsRemaining = 0;
  }

  /// Limpia la sesión completa ante cierre de sesión de usuario.
  Future<void> clearSession() async {
    _cancelLockoutTimer();
    _failedAttempts = 0;
    await preferencesService.clearChildModeSession();
    emit(const ChildModeInactive());
  }

  @override
  Future<void> close() {
    _cancelLockoutTimer();
    return super.close();
  }
}

