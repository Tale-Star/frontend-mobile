import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../../domain/repositories/parental_pin_repository.dart';
import '../datasources/parental_pin_remote_datasource.dart';

/// Implementación de producción de [ParentalPinRepository] consumiendo la API de Tale Star.
class ParentalPinRepositoryImpl implements ParentalPinRepository {
  final ParentalPinRemoteDataSource remoteDataSource;

  ParentalPinRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> setParentalPin({
    required String currentPassword,
    required String pin,
  }) async {
    try {
      final userModel = await remoteDataSource.setParentalPin(
        currentPassword: currentPassword,
        pin: pin,
      );
      return userModel;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos guardar tu PIN parental. Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<bool> validateParentalPin({required String pin}) async {
    try {
      final isValid = await remoteDataSource.validateParentalPin(pin: pin);
      return isValid;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on PinValidationException catch (e) {
      throw PinValidationFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'Ocurrió un error al verificar tu PIN parental.',
      );
    }
  }
}

