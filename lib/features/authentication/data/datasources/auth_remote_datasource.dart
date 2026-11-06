import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

/// Contrato del origen de datos remoto para autenticación.
abstract class AuthRemoteDataSource {
  /// Inicia sesión enviando [LoginRequestModel] a `/api/v1/auth/login`.
  Future<AuthResponseModel> login(LoginRequestModel request);

  /// Registra una cuenta enviando [RegisterRequestModel] a `/api/v1/auth/register`.
  Future<AuthResponseModel> register(RegisterRequestModel request);

  /// Obtiene los datos del perfil actual consultando `/api/v1/auth/me`.
  Future<UserModel> getProfile();
}

/// Implementación basada en Dio del origen de datos remoto.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'Respuesta inesperada al iniciar sesión.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al procesar la solicitud: $e',
      );
    }
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'Respuesta inesperada durante el registro.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al procesar el registro: $e',
      );
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.me);

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'No se pudo recuperar la información del perfil.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al consultar el perfil: $e',
      );
    }
  }

  Never _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException(
        message: 'No fue posible conectar con el servidor. Comprueba tu conexión a internet.',
      );
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode == 401) {
      throw const UnauthorizedException(
        message: 'El correo electrónico o la contraseña son incorrectos. Por favor, revísalos.',
      );
    }

    if (statusCode == 409) {
      throw const ServerException(
        message: 'Ya existe una cuenta registrada con este correo electrónico.',
        statusCode: 409,
      );
    }

    if (statusCode == 422) {
      String validationMsg = 'Los datos ingresados no cumplen con los requisitos mínimos.';
      if (responseData is Map<String, dynamic>) {
        final errorObj = responseData['error'];
        if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
          validationMsg = errorObj['message'] as String;
        }
      }
      throw ServerException(
        message: validationMsg,
        statusCode: 422,
      );
    }

    String message = 'Tuvimos un problema al comunicarnos con el servidor. Inténtalo de nuevo.';
    if (responseData is Map<String, dynamic>) {
      final errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
        message = errorObj['message'] as String;
      }
    }

    throw ServerException(
      message: message,
      statusCode: statusCode,
    );
  }
}

