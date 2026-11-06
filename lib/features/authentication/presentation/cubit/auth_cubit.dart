import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit que administra el ciclo de vida y estado de la sesión de usuario.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthInitial());

  /// Comprueba silenciosamente al iniciar la app si hay una sesión activa persistida.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  /// Inicia sesión con correo y contraseña, respetando la preferencia [rememberMe].
  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      emit(Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (e) {
      emit(const AuthError('No fue posible iniciar sesión. Por favor, intenta de nuevo.'));
    }
  }

  /// Registra una nueva cuenta de tutor o docente.
  Future<void> register({
    required String email,
    required String displayName,
    required String password,
    String? parentalPin,
    required bool rememberMe,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.register(
        email: email,
        displayName: displayName,
        password: password,
        parentalPin: parentalPin,
        rememberMe: rememberMe,
      );
      emit(Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (e) {
      emit(const AuthError('No fue posible registrar la cuenta. Por favor, intenta de nuevo.'));
    }
  }

  /// Cierra la sesión activa y purga credenciales locales.
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } finally {
      emit(const Unauthenticated());
    }
  }

  /// Flujo asistido / simulado de recuperación de contraseña (US04).
  Future<void> requestPasswordReset({required String email}) async {
    emit(const AuthLoading());
    try {
      await authRepository.requestPasswordReset(email: email);
      emit(PasswordResetSent(email));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (e) {
      emit(const AuthError('No se pudo procesar la solicitud de recuperación.'));
    }
  }

  /// Actualiza reactivamente el estado de configuración del PIN parental del usuario activo.
  void updateUserPinConfigured(bool pinConfigured) {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      emit(Authenticated(currentUser.copyWith(pinConfigured: pinConfigured)));
    }
  }

  /// Restablece el estado de error para permitir reintentos limpios.
  void clearError() {
    if (state is AuthError) {
      emit(const Unauthenticated());
    }
  }
}

