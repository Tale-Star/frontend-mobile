/// Constantes generales de la aplicación Tale Star.
abstract class AppConstants {
  static const String appName = 'Tale Star';

  // PIN Parental
  static const int pinLength = 4;
  static const int maxFailedPinAttempts = 3;
  static const Duration pinLockoutDuration = Duration(seconds: 30);

  // Claves de almacenamiento seguro y preferencias
  static const String secureKeyAccessToken = 'ts_secure_access_token';
  static const String prefKeyRememberMe = 'ts_pref_remember_me';
  static const String prefKeyChildModeActive = 'ts_pref_child_mode_active';
  static const String prefKeyChildModeContentType = 'ts_pref_child_mode_content_type';
  static const String prefKeyChildModeContentId = 'ts_pref_child_mode_content_id';
  static const String prefKeyChildModeContentTitle = 'ts_pref_child_mode_content_title';
  static const String prefKeyChildModeRouteContext = 'ts_pref_child_mode_route_context';
  static const String prefKeyChildModeUserId = 'ts_pref_child_mode_user_id';
  static const String prefKeyCurrentUserId = 'ts_pref_current_user_id';
  static const String prefKeyThemeMode = 'ts_pref_theme_mode';

  // Límites de paginación y debouncing
  static const int defaultPageSize = 20;
  static const Duration searchDebounce = Duration(milliseconds: 400);

  // AR Constants
  static const Duration arMaxStartupDuration = Duration(seconds: 3); // QAS07
}
