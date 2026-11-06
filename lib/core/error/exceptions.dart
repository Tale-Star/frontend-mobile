/// Excepciones lanzadas por la capa de infraestructura (Data sources, red, almacenamiento).
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({
    this.message = 'Sesión caducada o credenciales inválidas. Por favor, inicia sesión nuevamente.',
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'No fue posible conectar con el servidor. Comprueba tu conexión a internet.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    required this.message,
  });

  @override
  String toString() => 'CacheException: $message';
}

class PinValidationException implements Exception {
  final String message;

  const PinValidationException({
    required this.message,
  });

  @override
  String toString() => 'PinValidationException: $message';
}
