import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import 'profile_state.dart';

/// Cubit que administra la consulta, recarga y sincronización de datos de perfil (Fase 7).
class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository;
  final AuthCubit? _authCubit;

  ProfileCubit({
    required AuthRepository authRepository,
    AuthCubit? authCubit,
  })  : _authRepository = authRepository,
        _authCubit = authCubit,
        super(const ProfileInitial());

  /// Carga la información del usuario autenticado consultando el repositorio.
  Future<void> loadProfile({UserEntity? initialUser}) async {
    if (initialUser != null) {
      emit(ProfileLoaded(user: initialUser));
    } else {
      emit(const ProfileLoading());
    }

    try {
      final user = await _authRepository.getProfile();
      if (!isClosed) {
        emit(ProfileLoaded(user: user));
        _authCubit?.updateUserPinConfigured(user.pinConfigured);
      }
    } on NetworkFailure catch (f) {
      if (!isClosed && state is! ProfileLoaded) {
        emit(ProfileError(message: f.message, isNetworkError: true));
      }
    } on Failure catch (f) {
      if (!isClosed && state is! ProfileLoaded) {
        emit(ProfileError(message: f.message));
      }
    } catch (_) {
      if (!isClosed && state is! ProfileLoaded) {
        emit(const ProfileError(
          message: 'No pudimos conectar con el servidor de Tale Star. Revisa tu conexión a internet.',
          isNetworkError: true,
        ));
      }
    }
  }

  /// Recarga forzosa de la información del perfil (pull-to-refresh o reintento).
  Future<void> refresh() async {
    emit(const ProfileLoading());
    try {
      final user = await _authRepository.getProfile();
      if (!isClosed) {
        emit(ProfileLoaded(user: user));
        _authCubit?.updateUserPinConfigured(user.pinConfigured);
      }
    } on Failure catch (f) {
      if (!isClosed) {
        emit(ProfileError(message: f.message, isNetworkError: f is NetworkFailure));
      }
    } catch (_) {
      if (!isClosed) {
        emit(const ProfileError(
          message: 'No pudimos actualizar tu perfil. Intenta de nuevo en unos momentos.',
          isNetworkError: true,
        ));
      }
    }
  }

  /// Actualiza reactivamente el estado de configuración del PIN parental.
  void updatePinConfigured(bool configured) {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).user;
      emit(ProfileLoaded(user: current.copyWith(pinConfigured: configured)));
      _authCubit?.updateUserPinConfigured(configured);
    }
  }
}

