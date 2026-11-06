import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

/// Servicio HTTP personalizado para CacheManager que inyecta el token Bearer JWT.
class AuthenticatedHttpFileService extends HttpFileService {
  final SecureStorageService _secureStorageService;

  AuthenticatedHttpFileService({
    required SecureStorageService secureStorageService,
    super.httpClient,
  })  : _secureStorageService = secureStorageService;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final mergedHeaders = Map<String, String>.from(headers ?? {});
    // Inyectar token solo si no viene ya presente y no exponerlo en logs ni URLs
    if (!mergedHeaders.containsKey('Authorization')) {
      final token = await _secureStorageService.getToken();
      if (token != null && token.trim().isNotEmpty) {
        mergedHeaders['Authorization'] = 'Bearer $token';
      }
    }
    mergedHeaders['Accept'] = 'image/*, audio/*, application/octet-stream';

    try {
      final response = await super.get(url, headers: mergedHeaders);
      final statusCode = response.statusCode;
      if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
        throw HttpExceptionWithStatus(
          statusCode,
          'Error al recuperar recurso multimedia protegido (código $statusCode)',
          uri: Uri.parse(url),
        );
      }
      return response;
    } on HttpExceptionWithStatus {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthenticatedHttpFileService error en carga multimedia: $e');
      }
      rethrow;
    }
  }
}

/// Gestor de caché multimedia autenticado con aislamiento estricto de directorio por usuario.
///
/// Protege los recursos privados descargados de `/api/v1/media/assets/{id}`,
/// inyectando el header `Authorization: Bearer <token>` y aislando la caché
/// para evitar filtraciones de imágenes y audio entre diferentes usuarios
/// en el mismo dispositivo (QAS04).
class AuthenticatedCacheManager extends CacheManager with ImageCacheManager {
  static const String keyPrefix = 'ts_media_cache';
  static final Map<String, AuthenticatedCacheManager> _instances = {};

  final String userId;
  final SecureStorageService secureStorageService;

  AuthenticatedCacheManager._({
    required this.userId,
    required this.secureStorageService,
  }) : super(
          Config(
            '${keyPrefix}_$userId',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: '${keyPrefix}_$userId'),
            fileService: AuthenticatedHttpFileService(
              secureStorageService: secureStorageService,
            ),
          ),
        );

  /// Obtiene o inicializa la instancia aislada de caché para un [userId] específico.
  factory AuthenticatedCacheManager.forUser({
    required String userId,
    required SecureStorageService secureStorageService,
  }) {
    if (!_instances.containsKey(userId)) {
      _instances[userId] = AuthenticatedCacheManager._(
        userId: userId,
        secureStorageService: secureStorageService,
      );
    }
    return _instances[userId]!;
  }

  /// Limpia y purga el almacenamiento en caché del usuario especificado.
  static Future<void> clearUserCache(String userId) async {
    final instance = _instances.remove(userId);
    if (instance != null) {
      try {
        await instance.emptyCache();
        await instance.dispose();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error al limpiar caché de usuario $userId: $e');
        }
      }
    }
  }

  /// Desconecta y purga todas las instancias de caché activas (usado en logout).
  static Future<void> clearAllCaches() async {
    for (final instance in _instances.values) {
      try {
        await instance.emptyCache();
        await instance.dispose();
      } catch (_) {}
    }
    _instances.clear();
  }

  /// Resuelve la URL completa del recurso asegurando que rutas relativas del backend
  /// (ej: `/api/v1/media/assets/{id}`) incluyan la URL base activa de [AppConfig].
  static String resolveUrl(String? resourceUrl, {String? customBaseUrl}) {
    if (resourceUrl == null || resourceUrl.trim().isEmpty) {
      return '';
    }
    final trimmed = resourceUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = (customBaseUrl ?? AppConfig.instance.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  /// Genera los headers requeridos para la petición del asset.
  static Future<Map<String, String>> getAuthHeaders(
      SecureStorageService secureStorageService) async {
    final token = await secureStorageService.getToken();
    if (token != null && token.trim().isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }
}
