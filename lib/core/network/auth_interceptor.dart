import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor de Dio para autenticación JWT y manejo de 401 Unauthorized.
///
/// Inyecta automáticamente el header `Authorization: Bearer <token>`
/// y detecta respuestas 401 para notificar la caducidad de sesión.
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _secureStorageService;
  final void Function()? _onUnauthorized;

  AuthInterceptor({
    required SecureStorageService secureStorageService,
    void Function()? onUnauthorized,
  })  : _secureStorageService = secureStorageService,
        _onUnauthorized = onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    // No sobreescribir si ya viene un Authorization explícito
    if (!options.headers.containsKey('Authorization')) {
      final token = await _secureStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Notificar caducidad de sesión sin romper la cadena de error
      _onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
