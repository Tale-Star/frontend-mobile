import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/authenticated_cache.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

/// Implementación del repositorio de autenticación con soporte para sesiones
/// recordadas en almacenamiento cifrado o volátiles en memoria (US03).
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorageService;
  final PreferencesService preferencesService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorageService,
    required this.preferencesService,
  });

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await remoteDataSource.login(request);

      // Guardar token según la preferencia "Recordarme" (US03)
      await secureStorageService.saveToken(
        response.accessToken,
        rememberMe: rememberMe,
      );
      await preferencesService.setRememberMe(rememberMe);
      await preferencesService.setCurrentUserId(response.user.id);

      return response.user;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos completar tu inicio de sesión: $e',
      );
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String displayName,
    required String password,
    String? parentalPin,
    required bool rememberMe,
  }) async {
    try {
      final request = RegisterRequestModel(
        email: email,
        displayName: displayName,
        password: password,
        parentalPin: parentalPin,
      );
      final response = await remoteDataSource.register(request);

      // Guardar token según la preferencia "Recordarme" (US03)
      await secureStorageService.saveToken(
        response.accessToken,
        rememberMe: rememberMe,
      );
      await preferencesService.setRememberMe(rememberMe);
      await preferencesService.setCurrentUserId(response.user.id);

      return response.user;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos completar el registro: $e',
      );
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final hasToken = await secureStorageService.hasToken();
    if (!hasToken) {
      return null;
    }

    try {
      final user = await remoteDataSource.getProfile();
      await preferencesService.setCurrentUserId(user.id);
      return user;
    } on UnauthorizedException {
      // Si el token es inválido o expiró en el backend, se limpia la sesión local
      await logout();
      return null;
    } on NetworkException {
      // Ante fallo de red se conserva el estado local pero no se puede refrescar el perfil
      return null;
    } on ServerException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      await preferencesService.setCurrentUserId(user.id);
      return user;
    } on UnauthorizedException catch (e) {
      await logout();
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos recuperar tu perfil: $e',
      );
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    final hasToken = await secureStorageService.hasToken();
    if (!hasToken) {
      return false;
    }

    try {
      final user = await remoteDataSource.getProfile();
      await preferencesService.setCurrentUserId(user.id);
      return true;
    } catch (_) {
      // Si el token no es válido o hay un error de autenticación, consideramos desconectado
      final token = await secureStorageService.getToken();
      return token != null && token.isNotEmpty;
    }
  }

  @override
  Future<void> logout() async {
    await secureStorageService.deleteToken();
    await preferencesService.clearUserSession();
    await AuthenticatedCacheManager.clearAllCaches();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    // US04: El backend no implementa servicio SMTP en el MVP.
    // Se valida el correo y se simula la solicitud en cliente de forma asistida.
    if (email.trim().isEmpty) {
      throw const AuthFailure(
        message: 'Por favor, ingresa tu correo electrónico para enviarte las instrucciones.',
      );
    }
    // Breve espera para simular procesamiento
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

