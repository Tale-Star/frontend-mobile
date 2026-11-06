import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ambientes de ejecución soportados en Tale Star.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }

  String get envFileName {
    switch (this) {
      case AppEnvironment.staging:
        return 'environments/.env.staging';
      case AppEnvironment.production:
        return 'environments/.env.production';
      case AppEnvironment.development:
        return 'environments/.env.development';
    }
  }
}

/// Configuración centralizada de ambiente para la aplicación Tale Star.
class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableDebugLogs;
  final bool useMockData;
  final bool useMockAr;

  static AppConfig? _instance;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableDebugLogs,
    this.useMockData = false,
    this.useMockAr = false,
  });

  /// Instancia global de configuración.
  static AppConfig get instance {
    _instance ??= AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://10.0.2.2:8000',
      enableDebugLogs: true,
      useMockData: false,
      useMockAr: false,
    );
    return _instance!;
  }

  /// Verifica si la configuración ha sido inicializada explícitamente.
  static bool get isInitialized => _instance != null;

  /// Inicializa la configuración cargando el archivo de variables de entorno correspondiente.
  ///
  /// El orden de resolución del ambiente es:
  /// 1. Parámetro explícito [targetEnvironment].
  /// 2. Valor de compilación `--dart-define=APP_ENV=...`.
  /// 3. Por defecto [AppEnvironment.development].
  ///
  /// El modo mock de datos se habilita con `--dart-define=USE_MOCK_DATA=true`.
  /// El modo mock de AR se habilita con `--dart-define=USE_MOCK_AR=true`.
  /// Ambos están estrictamente restringidos a desarrollo (`development` y `kDebugMode`).
  /// En `staging` o `production`, siempre se evalúan como `false`.
  static Future<AppConfig> initialize({
    AppEnvironment? targetEnvironment,
    bool? overrideUseMockData,
    bool? overrideUseMockAr,
  }) async {
    final envName = const String.fromEnvironment('APP_ENV', defaultValue: '');
    final env = targetEnvironment ??
        (envName.isNotEmpty
            ? AppEnvironment.fromString(envName)
            : AppEnvironment.development);

    // Carga de archivo .env correspondiente con tolerancia a tests donde los assets no estén disponibles
    try {
      await dotenv.load(fileName: env.envFileName);
    } catch (_) {
      // En modo test o si el asset no está empaquetado, continuamos con fallbacks
    }

    final defaultUrl = switch (env) {
      AppEnvironment.staging => 'https://staging-api.talestar.app',
      AppEnvironment.production => 'https://api.talestar.app',
      AppEnvironment.development => 'http://10.0.2.2:8000',
    };

    final apiBaseUrl = dotenv.maybeGet('API_BASE_URL') ?? defaultUrl;
    final enableDebugLogs = dotenv.maybeGet('ENABLE_DEBUG_LOGS')?.toLowerCase() == 'true' ||
        (env != AppEnvironment.production);

    final mockFlag = overrideUseMockData ??
        const bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);
    final mockArFlag = overrideUseMockAr ??
        const bool.fromEnvironment('USE_MOCK_AR', defaultValue: false);

    // Regla de seguridad crítica: Mock Mode está estrictamente restringido al ambiente de desarrollo.
    // En staging y producción se prohíbe terminantemente su activación (siempre false).
    final bool isMockAllowed = env == AppEnvironment.development && kDebugMode;
    final bool useMockData = isMockAllowed && mockFlag;
    final bool useMockAr = isMockAllowed && mockArFlag;

    _instance = AppConfig(
      environment: env,
      apiBaseUrl: apiBaseUrl,
      enableDebugLogs: enableDebugLogs,
      useMockData: useMockData,
      useMockAr: useMockAr,
    );

    return _instance!;
  }

  /// Permite establecer una configuración fija (útil para pruebas unitarias).
  static void setMockConfig(AppConfig config) {
    _instance = config;
  }

  /// Restablece la configuración.
  static void reset() {
    _instance = null;
  }
}
