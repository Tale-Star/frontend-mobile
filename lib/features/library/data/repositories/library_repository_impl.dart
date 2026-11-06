import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/library_item_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_datasource.dart';

/// Implementación concreta del repositorio de biblioteca.
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remoteDataSource;

  LibraryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<LibraryItemEntity>> getLibraryItems({
    ContentType? type,
    String? query,
    bool? favorite,
  }) async {
    try {
      final models = await remoteDataSource.getLibraryItems(
        type: type?.value,
        q: query,
        favorite: favorite,
      );
      return models;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos cargar los contenidos de tu biblioteca: $e',
      );
    }
  }

  @override
  Future<LibraryItemEntity> getLibraryItem(String id) async {
    try {
      final model = await remoteDataSource.getLibraryItem(id);
      return model;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No se pudo cargar el elemento solicitado: $e',
      );
    }
  }

  @override
  Future<LibraryItemEntity> toggleFavorite(String id, bool newFavoriteStatus) async {
    try {
      final updatedModel = await remoteDataSource.patchLibraryItem(
        id,
        favorite: newFavoriteStatus,
      );
      return updatedModel;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No se pudo actualizar el estado de favorito: $e',
      );
    }
  }
}

