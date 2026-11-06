import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/story_page_model.dart';
import '../models/story_response_model.dart';

/// Contrato del datasource remoto para consultar historias y sus páginas.
abstract class ReaderRemoteDataSource {
  /// Consulta los detalles de un cuento (`GET /api/v1/stories/{story_id}`).
  Future<StoryResponseModel> getStory(String storyId);

  /// Consulta el listado de páginas de un cuento (`GET /api/v1/stories/{story_id}/pages`).
  Future<List<StoryPageModel>> getStoryPages(String storyId);
}

/// Implementación concreta del datasource remoto de lectura usando [Dio].
class ReaderRemoteDataSourceImpl implements ReaderRemoteDataSource {
  final Dio dio;

  ReaderRemoteDataSourceImpl({required this.dio});

  @override
  Future<StoryResponseModel> getStory(String storyId) async {
    try {
      final response = await dio.get(ApiConstants.storyDetail(storyId));
      if (response.statusCode == 200 && response.data != null) {
        return StoryResponseModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(
        message: 'Respuesta inválida del servidor al obtener el cuento.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e, fallbackMessage: 'No se pudo cargar el cuento solicitado.');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) rethrow;
      throw ServerException(message: 'Error inesperado al obtener el cuento: $e');
    }
  }

  @override
  Future<List<StoryPageModel>> getStoryPages(String storyId) async {
    try {
      final response = await dio.get(ApiConstants.storyPages(storyId));
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map((json) => StoryPageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw ServerException(
        message: 'Respuesta inválida del servidor al obtener las páginas.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e, fallbackMessage: 'No se pudieron cargar las páginas del cuento.');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) rethrow;
      throw ServerException(message: 'Error inesperado al obtener las páginas del cuento: $e');
    }
  }

  Never _handleDioException(DioException e, {required String fallbackMessage}) {
    final status = e.response?.statusCode;
    if (status == 401) {
      throw const UnauthorizedException(
        message: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
      );
    }
    if (status == 404) {
      throw ServerException(
        message: 'El cuento o páginas solicitadas no existen o pertenecen a otro usuario.',
        statusCode: 404,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException(
        message: 'No pudimos conectar con Tale Star. Revisa tu conexión a internet.',
      );
    }

    final serverMsg = (e.response?.data is Map)
        ? (e.response?.data['detail'] as String?)
        : null;

    throw ServerException(
      message: serverMsg ?? fallbackMessage,
      statusCode: status,
    );
  }
}

