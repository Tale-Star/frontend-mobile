import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Servicio de gestión de preferencias de usuario no confidenciales.
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // ---------------------------------------------------------------------------
  // Preferencia "Recordarme" (US03)
  // ---------------------------------------------------------------------------
  bool get rememberMe => _prefs.getBool(AppConstants.prefKeyRememberMe) ?? false;

  Future<bool> setRememberMe(bool value) =>
      _prefs.setBool(AppConstants.prefKeyRememberMe, value);

  // ---------------------------------------------------------------------------
  // Persistencia de Modo Niño ante reinicio de app
  // ---------------------------------------------------------------------------
  bool get isChildModeActive =>
      _prefs.getBool(AppConstants.prefKeyChildModeActive) ?? false;

  Future<bool> setChildModeActive(bool value) =>
      _prefs.setBool(AppConstants.prefKeyChildModeActive, value);

  String? get childModeContentType =>
      _prefs.getString(AppConstants.prefKeyChildModeContentType);

  String? get childModeContentId =>
      _prefs.getString(AppConstants.prefKeyChildModeContentId);

  String? get childModeContentTitle =>
      _prefs.getString(AppConstants.prefKeyChildModeContentTitle);

  String? get childModeRouteContext =>
      _prefs.getString(AppConstants.prefKeyChildModeRouteContext);

  String? get childModeUserId =>
      _prefs.getString(AppConstants.prefKeyChildModeUserId);

  Future<void> saveChildModeSession({
    required String contentType,
    required String contentId,
    required String title,
    required String routeContext,
    required String userId,
  }) async {
    await _prefs.setBool(AppConstants.prefKeyChildModeActive, true);
    await _prefs.setString(AppConstants.prefKeyChildModeContentType, contentType);
    await _prefs.setString(AppConstants.prefKeyChildModeContentId, contentId);
    await _prefs.setString(AppConstants.prefKeyChildModeContentTitle, title);
    await _prefs.setString(AppConstants.prefKeyChildModeRouteContext, routeContext);
    await _prefs.setString(AppConstants.prefKeyChildModeUserId, userId);
  }

  Future<void> clearChildModeSession() async {
    await _prefs.setBool(AppConstants.prefKeyChildModeActive, false);
    await _prefs.remove(AppConstants.prefKeyChildModeContentType);
    await _prefs.remove(AppConstants.prefKeyChildModeContentId);
    await _prefs.remove(AppConstants.prefKeyChildModeContentTitle);
    await _prefs.remove(AppConstants.prefKeyChildModeRouteContext);
    await _prefs.remove(AppConstants.prefKeyChildModeUserId);
  }

  // ---------------------------------------------------------------------------
  // Identificador del usuario activo (para aislamiento de caché por usuario)
  // ---------------------------------------------------------------------------
  String? get currentUserId => _prefs.getString(AppConstants.prefKeyCurrentUserId);

  Future<bool> setCurrentUserId(String? userId) {
    if (userId == null) {
      return _prefs.remove(AppConstants.prefKeyCurrentUserId);
    }
    return _prefs.setString(AppConstants.prefKeyCurrentUserId, userId);
  }

  // ---------------------------------------------------------------------------
  // Tema (light, dark, system)
  // ---------------------------------------------------------------------------
  String get themeMode =>
      _prefs.getString(AppConstants.prefKeyThemeMode) ?? 'system';

  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(AppConstants.prefKeyThemeMode, mode);

  // ---------------------------------------------------------------------------
  // Limpieza total al cerrar sesión
  // ---------------------------------------------------------------------------
  Future<void> clearUserSession() async {
    await setRememberMe(false);
    await clearChildModeSession();
    await setCurrentUserId(null);
  }
}
