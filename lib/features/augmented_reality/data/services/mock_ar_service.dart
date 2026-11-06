import 'dart:async';
import '../../domain/entities/ar_compatibility.dart';
import '../../domain/entities/ar_plane.dart';
import '../../domain/entities/ar_status_update.dart';
import '../../domain/repositories/ar_service.dart';

/// Implementación simulada de [ArService] para pruebas unitarias, de widgets y Modo Demostración.
class MockArService implements ArService {
  bool isDeviceSupported;
  bool permissionGranted;
  bool simulatePlaneDetection;
  String deviceModel;

  final StreamController<List<ArPlane>> _planesController =
      StreamController<List<ArPlane>>.broadcast();

  final StreamController<ArStatusUpdate> _statusController =
      StreamController<ArStatusUpdate>.broadcast();

  bool _isSessionActive = false;
  String? _placedPlaneId;

  MockArService({
    this.isDeviceSupported = true,
    this.permissionGranted = true,
    this.simulatePlaneDetection = true,
    this.deviceModel = 'Dispositivo de prueba (Modo Simulado)',
  });

  @override
  Stream<List<ArPlane>> get planesStream => _planesController.stream;

  @override
  Stream<ArStatusUpdate> get statusStream => _statusController.stream;

  String? get placedPlaneId => _placedPlaneId;
  bool get isSessionActive => _isSessionActive;

  @override
  Future<ArCompatibilityInfo> checkCompatibility() async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (isDeviceSupported) {
      return ArCompatibilityInfo(
        isSupported: true,
        availability: ArCoreAvailability.supportedInstalled,
        deviceModel: deviceModel,
        userMessage: 'Dispositivo compatible con Realidad Aumentada (Simulación).',
      );
    } else {
      return ArCompatibilityInfo(
        isSupported: false,
        availability: ArCoreAvailability.unsupportedDeviceNotCapable,
        deviceModel: deviceModel,
        userMessage:
            'Tu dispositivo ($deviceModel) no cuenta con la certificación oficial de Google ARCore para rastreo de superficies.',
      );
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    return permissionGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return permissionGranted;
  }

  @override
  Future<void> initializeSession() async {
    final compatibility = await checkCompatibility();
    if (!compatibility.isSupported) {
      throw UnsupportedError(compatibility.userMessage);
    }

    if (!permissionGranted) {
      throw StateError('Permiso de cámara denegado.');
    }

    _isSessionActive = true;

    if (simulatePlaneDetection) {
      // Simula detección tras un breve rastreo
      Timer(const Duration(milliseconds: 400), () {
        if (_isSessionActive && !_planesController.isClosed) {
          _planesController.add([
            const ArPlane(
              id: 'plane-mesa-01',
              type: ArPlaneType.horizontalUpward,
              extentX: 1.2,
              extentZ: 0.8,
              centerPoseX: 0.0,
              centerPoseY: -0.2,
              centerPoseZ: -0.9,
            ),
          ]);
          if (!_statusController.isClosed) {
            _statusController.add(const ArStatusUpdate(
              sessionState: 'ACTIVE',
              cameraTrackingState: 'TRACKING',
              trackingFailureReason: 'NONE',
              knownPlanesCount: 1,
              validPlanesCount: 1,
              hasValidPlacementPoint: true,
              hasHitAtReticle: true,
              placementPointType: 'CONFIRMED_PLANE',
              hitDistanceMeters: 0.85,
            ));
          }
        }
      });
    }
  }

  @override
  Future<bool> placeStoryAnchor(String planeId) async {
    if (!_isSessionActive) return false;
    _placedPlaneId = planeId;
    return true;
  }

  @override
  Future<bool> placeStoryAtCoordinates(double x, double y) async {
    if (!_isSessionActive) return false;
    _placedPlaneId = 'plane-mesa-01';
    return true;
  }

  @override
  Future<void> stopSession() async {
    _isSessionActive = false;
    _placedPlaneId = null;
  }

  @override
  Future<void> dispose() async {
    await stopSession();
    await _planesController.close();
    await _statusController.close();
  }
}

