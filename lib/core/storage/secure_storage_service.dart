import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Servicio de almacenamiento seguro para credenciales sensibles (JWT).
///
/// Implementa la estrategia de sesión de la US03:
/// - Si "Recordarme" está activado: el token se persiste en el Keystore/SharedPreferences cifrado.
/// - Si "Recordarme" no está activado: el token se conserva **exclusivamente en memoria volátil**.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Almacén volátil en memoria para sesiones no persistidas ("Recordarme" = false)
  String? _volatileToken;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Guarda el token según la preferencia de persistencia de US03.
  Future<void> saveToken(String token, {required bool rememberMe}) async {
    _volatileToken = token;
    if (rememberMe) {
      await _storage.write(
        key: AppConstants.secureKeyAccessToken,
        value: token,
      );
    } else {
      // Limpia el almacenamiento seguro por si existía un token previo
      await _storage.delete(key: AppConstants.secureKeyAccessToken);
    }
  }

  /// Recupera el token activo.
  ///
  /// Retorna primero el token en memoria volátil si existe.
  /// Si no existe en memoria, busca en almacenamiento seguro (sesión recordada).
  Future<String?> getToken() async {
    if (_volatileToken != null && _volatileToken!.isNotEmpty) {
      return _volatileToken;
    }
    final persistedToken = await _storage.read(key: AppConstants.secureKeyAccessToken);
    if (persistedToken != null && persistedToken.isNotEmpty) {
      _volatileToken = persistedToken;
      return persistedToken;
    }
    return null;
  }

  /// Elimina el token tanto de memoria volátil como del almacenamiento seguro.
  Future<void> deleteToken() async {
    _volatileToken = null;
    await _storage.delete(key: AppConstants.secureKeyAccessToken);
  }

  /// Comprueba si existe un token válido (en memoria o persistido).
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
