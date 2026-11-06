import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/story_detail.dart';
import '../../domain/entities/story_page_detail.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/reader_remote_datasource.dart';
import '../models/story_page_model.dart';

/// Implementación concreta del repositorio de lectura de cuentos.
class ReaderRepositoryImpl implements ReaderRepository {
  final ReaderRemoteDataSource remoteDataSource;

  ReaderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<StoryDetail> getStory(String storyId) async {
    try {
      final model = await remoteDataSource.getStory(storyId);
      return model;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos cargar la información del cuento: $e',
      );
    }
  }

  @override
  Future<List<StoryPageDetail>> getStoryPages(String storyId) async {
    try {
      final models = await remoteDataSource.getStoryPages(storyId);
      // Garantizar ordenamiento ascendente por page_number
      final sortedModels = List<StoryPageModel>.from(models)
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      return sortedModels;
    } on UnauthorizedException catch (e) {
      throw AuthFailure(message: e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(
        message: 'No pudimos cargar las páginas de este cuento: $e',
      );
    }
  }
}

