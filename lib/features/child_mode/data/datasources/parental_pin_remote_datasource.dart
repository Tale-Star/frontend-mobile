import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../authentication/data/models/user_model.dart';
import '../models/set_parental_pin_request_model.dart';
import '../models/validate_parental_pin_request_model.dart';
import '../models/validate_parental_pin_response_model.dart';

/// Contrato del origen de datos remoto para administración de PIN parental.
abstract class ParentalPinRemoteDataSource {
  /// Establece o actualiza el PIN parental mediante `PUT /api/v1/auth/parental-pin`.
  Future<UserModel> setParentalPin({
    required String currentPassword,
    required String pin,
  });

  /// Valida el PIN parental mediante `POST /api/v1/auth/parental-pin/validate`.
  Future<bool> validateParentalPin({
    required String pin,
  });
}

/// Implementación real basada en [Dio].
class ParentalPinRemoteDataSourceImpl implements ParentalPinRemoteDataSource {
  final Dio dio;

  ParentalPinRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> setParentalPin({
    required String currentPassword,
    required String pin,
  }) async {
    try {
      final request = SetParentalPinRequestModel(
        currentPassword: currentPassword,
        pin: pin,
      );

      final response = await dio.put(
        ApiConstants.parentalPin,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'Respuesta inesperada al configurar el PIN parental.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleSetPinDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al configurar el PIN: $e',
      );
    }
  }

  @override
  Future<bool> validateParentalPin({required String pin}) async {
    try {
      final request = ValidateParentalPinRequestModel(pin: pin);

      final response = await dio.post(
        ApiConstants.validateParentalPin,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final model = ValidateParentalPinResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return model.valid;
      }

      throw ServerException(
        message: 'Respuesta inesperada al validar el PIN parental.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleValidatePinDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException || e is PinValidationException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al validar el PIN: $e',
      );
    }
  }

  Never _handleSetPinDioException(DioException e) {
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
        message: 'La contraseña actual ingresada es incorrecta. Por favor verifícala.',
      );
    }

    if (statusCode == 422) {
      String msg = 'El PIN debe contener exactamente 4 dígitos numéricos.';
      if (responseData is Map<String, dynamic>) {
        final errorObj = responseData['error'];
        if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
          msg = errorObj['message'] as String;
        }
      }
      throw ServerException(message: msg, statusCode: 422);
    }

    String message = 'Tuvimos un problema al guardar tu PIN. Inténtalo de nuevo.';
    if (responseData is Map<String, dynamic>) {
      final errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
        message = errorObj['message'] as String;
      }
    }

    throw ServerException(message: message, statusCode: statusCode);
  }

  Never _handleValidatePinDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException(
        message: 'No se pudo verificar el PIN debido a un problema de conexión. El modo protegido continúa activo.',
      );
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode == 401) {
      throw const UnauthorizedException(
        message: 'Tu sesión ha caducado. Vuelve a iniciar sesión para gestionar tu cuenta.',
      );
    }

    if (statusCode == 422) {
      throw const PinValidationException(
        message: 'El PIN debe contener exactamente 4 dígitos numéricos.',
      );
    }

    String message = 'No fue posible validar el PIN parental. Inténtalo nuevamente.';
    if (responseData is Map<String, dynamic>) {
      final errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
        message = errorObj['message'] as String;
      }
    }

    throw ServerException(message: message, statusCode: statusCode);
  }
}

