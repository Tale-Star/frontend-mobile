import '../config/app_config.dart';

/// Constantes de configuración de la API REST de Tale Star.
///
/// Los endpoints aquí definidos han sido verificados contra los contratos
/// oficiales del backend FastAPI (§5.3 del README y OpenAPI).
abstract class ApiConstants {
  /// URL base por defecto (loopback para emulador de desarrollo).
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  /// URL base activa provista centralizadamente por [AppConfig].
  static String get baseUrl => AppConfig.instance.apiBaseUrl;

  static const String apiVersion = '/api/v1';

  // ---------------------------------------------------------------------------
  // Endpoints de Autenticación y Control Parental
  // ---------------------------------------------------------------------------
  static const String register = '$apiVersion/auth/register';
  static const String login = '$apiVersion/auth/login';
  static const String me = '$apiVersion/auth/me';
  static const String parentalPin = '$apiVersion/auth/parental-pin';
  static const String validateParentalPin = '$apiVersion/auth/parental-pin/validate';

  // ---------------------------------------------------------------------------
  // Endpoints de Biblioteca de Creaciones
  // ---------------------------------------------------------------------------
  static const String library = '$apiVersion/library';
  static String libraryItem(String id) => '$apiVersion/library/$id';

  // ---------------------------------------------------------------------------
  // Endpoints de Cuentos (Lector 2D y AR)
  // ---------------------------------------------------------------------------
  static const String stories = '$apiVersion/stories';
  static String storyDetail(String id) => '$apiVersion/stories/$id';
  static String storyPages(String id) => '$apiVersion/stories/$id/pages';

  // ---------------------------------------------------------------------------
  // Endpoints Multimedia Protegida (Caché Bearer JWT)
  // ---------------------------------------------------------------------------
  static String mediaAsset(String id) => '$apiVersion/media/assets/$id';

  // Timeouts de red (ms)
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
