import '../entities/ar_compatibility.dart';
import '../entities/ar_plane.dart';
import '../entities/ar_status_update.dart';

/// Contrato de servicio para interacción con el subsistema de Realidad Aumentada.
abstract class ArService {
  /// Verifica si el hardware y el sistema operativo soportan ARCore oficialmente.
  Future<ArCompatibilityInfo> checkCompatibility();

  /// Solicita el permiso de cámara del sistema operativo al usuario.
  Future<bool> requestCameraPermission();

  /// Comprueba si el permiso de cámara está concedido sin solicitarlo.
  Future<bool> hasCameraPermission();

  /// Inicializa la sesión nativa de ARCore y activa el tracking SLAM.
  Future<void> initializeSession();

  /// Flujo continuo de planos o superficies detectadas en el entorno físico.
  Stream<List<ArPlane>> get planesStream;

  /// Flujo de telemetría de diagnóstico, tracking y retícula en tiempo real.
  Stream<ArStatusUpdate> get statusStream;

  /// Ancla virtualmente el cuento a la superficie plana identificada por [planeId].
  Future<bool> placeStoryAnchor(String planeId);

  /// Ancla virtualmente el cuento en una coordenada específica de pantalla mediante hit-test.
  Future<bool> placeStoryAtCoordinates(double x, double y);

  /// Detiene la sesión AR, apaga la cámara y libera recursos nativos.
  Future<void> stopSession();

  /// Libera por completo los canales y recursos.
  Future<void> dispose();
}

