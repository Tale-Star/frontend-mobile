import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/library_item_model.dart';

/// Contrato del origen de datos remoto para la biblioteca de contenidos.
abstract class LibraryRemoteDataSource {
  /// Consulta los elementos de biblioteca aplicando filtros opcionales.
  Future<List<LibraryItemModel>> getLibraryItems({
    String? type,
    String? q,
    bool? favorite,
  });

  /// Consulta un elemento específico por su ID.
  Future<LibraryItemModel> getLibraryItem(String id);

  /// Actualiza propiedades de un elemento (`PATCH /api/v1/library/{id}`).
  Future<LibraryItemModel> patchLibraryItem(
    String id, {
    bool? favorite,
    String? name,
    String? description,
  });
}

/// Implementación basada en Dio del origen de datos de biblioteca.
class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final Dio dio;

  LibraryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<LibraryItemModel>> getLibraryItems({
    String? type,
    String? q,
    bool? favorite,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (q != null && q.trim().isNotEmpty) {
        queryParams['q'] = q.trim();
      }
      if (favorite != null) {
        queryParams['favorite'] = favorite;
      }

      final response = await dio.get(
        ApiConstants.library,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => LibraryItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(
        message: 'Respuesta inválida del servidor al listar la biblioteca.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error inesperado al consultar la biblioteca: $e',
      );
    }
  }

  @override
  Future<LibraryItemModel> getLibraryItem(String id) async {
    try {
      final response = await dio.get(ApiConstants.libraryItem(id));

      if (response.statusCode == 200 && response.data != null) {
        return LibraryItemModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'No fue posible obtener el detalle del elemento.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error al obtener el elemento de biblioteca: $e',
      );
    }
  }

  @override
  Future<LibraryItemModel> patchLibraryItem(
    String id, {
    bool? favorite,
    String? name,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (favorite != null) body['favorite'] = favorite;
      if (name != null) body['name'] = name.trim();
      if (description != null) body['description'] = description.trim();

      final response = await dio.patch(
        ApiConstants.libraryItem(id),
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        return LibraryItemModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: 'No se pudo actualizar el elemento de biblioteca.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'Ocurrió un error al actualizar el elemento: $e',
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
        message: 'Tu sesión ha expirado. Por favor, ingresa de nuevo.',
      );
    }

    if (statusCode == 404) {
      throw const ServerException(
        message: 'El contenido solicitado no fue encontrado en tu biblioteca.',
        statusCode: 404,
      );
    }

    if (statusCode == 422) {
      String validationMsg = 'Los criterios de búsqueda no son válidos.';
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

    String message = 'Tuvimos un problema al comunicarnos con la biblioteca.';
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

