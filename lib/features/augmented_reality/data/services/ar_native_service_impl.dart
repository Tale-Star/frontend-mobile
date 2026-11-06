import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/ar_compatibility.dart';
import '../../domain/entities/ar_plane.dart';
import '../../domain/entities/ar_status_update.dart';
import '../../domain/repositories/ar_service.dart';

/// Implementación real que se comunica con el subsistema nativo de Android y Google ARCore mediante MethodChannel.
class ArNativeServiceImpl implements ArService {
  static const MethodChannel _channel = MethodChannel('com.startale.startale_mobile/ar_core');

  final StreamController<List<ArPlane>> _planesController =
      StreamController<List<ArPlane>>.broadcast();

  final StreamController<ArStatusUpdate> _statusController =
      StreamController<ArStatusUpdate>.broadcast();

  bool _isSessionActive = false;
  int _eventsReceivedCount = 0;
  List<ArPlane> _cachedPlanes = [];
  ArStatusUpdate? _cachedStatus;

  ArNativeServiceImpl() {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  @override
  Stream<List<ArPlane>> get planesStream async* {
    if (_cachedPlanes.isNotEmpty) {
      yield List.unmodifiable(_cachedPlanes);
    }
    yield* _planesController.stream;
  }

  @override
  Stream<ArStatusUpdate> get statusStream async* {
    if (_cachedStatus != null) {
      yield _cachedStatus!;
    }
    yield* _statusController.stream;
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onPlanesUpdated') {
      final rawList = call.arguments;
      if (rawList is List) {
        final planes = <ArPlane>[];
        for (final item in rawList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            planes.add(ArPlane(
              id: map['id']?.toString() ?? 'plane',
              type: map['type'] == 'horizontalDownward'
                  ? ArPlaneType.horizontalDownward
                  : ArPlaneType.horizontalUpward,
              extentX: (map['extentX'] as num?)?.toDouble() ?? 1.0,
              extentZ: (map['extentZ'] as num?)?.toDouble() ?? 1.0,
              centerPoseX: (map['centerPoseX'] as num?)?.toDouble() ?? 0.0,
              centerPoseY: (map['centerPoseY'] as num?)?.toDouble() ?? 0.0,
              centerPoseZ: (map['centerPoseZ'] as num?)?.toDouble() ?? 0.0,
            ));
          }
        }
        _cachedPlanes = planes;
        if (!_planesController.isClosed) {
          _planesController.add(planes);
        }
      }
    } else if (call.method == 'onArStatusUpdated') {
      _eventsReceivedCount++;
      final rawMap = call.arguments;
      if (rawMap is Map) {
        final map = Map<String, dynamic>.from(rawMap);
        final status = ArStatusUpdate(
          sessionState: map['sessionState']?.toString() ?? 'ACTIVE',
          cameraTrackingState: map['cameraTrackingState']?.toString() ?? 'UNKNOWN',
          trackingFailureReason: map['trackingFailureReason']?.toString() ?? 'NONE',
          frameTimestampNs: (map['frameTimestampNs'] as num?)?.toInt() ?? 0,
          eventsSentCount: (map['eventsSentCount'] as num?)?.toInt() ?? 0,
          eventsReceivedCount: _eventsReceivedCount,
          knownPlanesCount: (map['knownPlanesCount'] as num?)?.toInt() ?? 0,
          validPlanesCount: (map['validPlanesCount'] as num?)?.toInt() ?? 0,
          nonHorizontalPlanesCount: (map['nonHorizontalPlanesCount'] as num?)?.toInt() ?? 0,
          pausedPlanesCount: (map['pausedPlanesCount'] as num?)?.toInt() ?? 0,
          subsumedPlanesCount: (map['subsumedPlanesCount'] as num?)?.toInt() ?? 0,
          planeDiscardReason: map['planeDiscardReason']?.toString() ?? 'ARCore buscando superficies...',
          hasValidPlacementPoint: map['hasValidPlacementPoint'] == true,
          hasHitAtReticle: map['hasHitAtReticle'] == true,
          placementPointType: map['placementPointType']?.toString() ?? 'NONE',
          hitDistanceMeters: (map['hitDistanceMeters'] as num?)?.toDouble() ?? 0.0,
          anchorScreenX: (map['anchorScreenX'] as num?)?.toDouble() ?? 0.0,
          anchorScreenY: (map['anchorScreenY'] as num?)?.toDouble() ?? 0.0,
          anchorNormX: (map['anchorNormX'] as num?)?.toDouble() ?? 0.5,
          anchorNormY: (map['anchorNormY'] as num?)?.toDouble() ?? 0.5,
          anchorDistance: (map['anchorDistance'] as num?)?.toDouble() ?? 0.0,
          anchorYaw: (map['anchorYaw'] as num?)?.toDouble() ?? 0.0,
          anchorPitch: (map['anchorPitch'] as num?)?.toDouble() ?? 0.0,
          isAnchorTracking: map['isAnchorTracking'] == true,
          isAnchorInView: map['isAnchorInView'] == true,
          viewportWidth: (map['viewportWidth'] as num?)?.toDouble() ?? 1080.0,
          viewportHeight: (map['viewportHeight'] as num?)?.toDouble() ?? 2400.0,
        );
        _cachedStatus = status;
        if (!_statusController.isClosed) {
          _statusController.add(status);
        }
      }
    }
  }

  @override
  Future<ArCompatibilityInfo> checkCompatibility() async {
    if (!Platform.isAndroid) {
      return const ArCompatibilityInfo(
        isSupported: false,
        availability: ArCoreAvailability.unsupportedDeviceNotCapable,
        deviceModel: 'iOS / Plataforma no soportada para ARCore en MVP',
        userMessage: 'La experiencia de Realidad Aumentada requiere Android con Google ARCore.',
      );
    }

    try {
      // 1. Obtener información de hardware dinámicamente desde Android
      String deviceModel = 'Android Hardware';
      try {
        final dynamic info = await _channel.invokeMethod('getDeviceInfo');
        if (info is Map) {
          final manufacturer = info['manufacturer']?.toString() ?? '';
          final brand = info['brand']?.toString() ?? '';
          final model = info['model']?.toString() ?? '';
          final name = brand.isNotEmpty ? brand : manufacturer;
          if (name.isNotEmpty && model.isNotEmpty) {
            deviceModel = '$name $model';
          } else if (model.isNotEmpty) {
            deviceModel = model;
          }
        }
      } catch (_) {
        // Fallback a descriptor genérico en caso de error de lectura de Build
      }

      // 2. Consultar disponibilidad con tolerancia a estados transitorios
      String? result = await _channel.invokeMethod<String>('checkArAvailability');
      if (result == 'UNKNOWN_CHECKING') {
        await Future.delayed(const Duration(milliseconds: 300));
        result = await _channel.invokeMethod<String>('checkArAvailability');
      }

      final availability = ArCoreAvailability.fromNativeString(result);
      final isSupported = availability == ArCoreAvailability.supportedInstalled ||
          availability == ArCoreAvailability.supportedNotInstalled;

      String message;
      switch (availability) {
        case ArCoreAvailability.supportedInstalled:
          message = 'Dispositivo ($deviceModel) certificado y listo para Realidad Aumentada.';
          break;
        case ArCoreAvailability.supportedNotInstalled:
          message = 'Tu dispositivo ($deviceModel) es compatible, pero necesitas instalar Servicios de Google Play para RA.';
          break;
        case ArCoreAvailability.supportedApkTooOld:
          message = 'Actualiza Servicios de Google Play para RA en tu dispositivo ($deviceModel).';
          break;
        case ArCoreAvailability.unsupportedDeviceNotCapable:
          message = 'Tu dispositivo ($deviceModel) no cuenta con la certificación oficial de Google ARCore para rastreo de superficies.';
          break;
        case ArCoreAvailability.unknownChecking:
          message = 'Comprobando compatibilidad de Realidad Aumentada con Google...';
          break;
        case ArCoreAvailability.unknownError:
          message = 'No fue posible determinar la compatibilidad de Realidad Aumentada en $deviceModel.';
          break;
      }

      return ArCompatibilityInfo(
        isSupported: isSupported,
        availability: availability,
        deviceModel: deviceModel,
        userMessage: message,
      );
    } catch (e) {
      return ArCompatibilityInfo(
        isSupported: false,
        availability: ArCoreAvailability.unknownError,
        deviceModel: 'Desconocido',
        userMessage: 'Error al consultar ARCore nativo: $e',
      );
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final bool? nativePerm = await _channel.invokeMethod<bool>('hasCameraPermission');
      if (nativePerm != null) return nativePerm;
    } catch (_) {}
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      await _channel.invokeMethod('requestCameraPermission');
    } catch (_) {}
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<void> initializeSession() async {
    final compatibility = await checkCompatibility();
    if (!compatibility.isSupported) {
      throw UnsupportedError(compatibility.userMessage);
    }

    final hasPerm = await hasCameraPermission();
    if (!hasPerm) {
      final granted = await requestCameraPermission();
      if (!granted) {
        throw StateError('Permiso de cámara no concedido para Realidad Aumentada.');
      }
    }

    try {
      await _channel.invokeMethod('initializeSession');
    } catch (_) {}

    _isSessionActive = true;
  }

  @override
  Future<bool> placeStoryAnchor(String planeId) async {
    if (!_isSessionActive) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'placeStoryAnchor',
        {'planeId': planeId},
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> placeStoryAtCoordinates(double x, double y) async {
    if (!_isSessionActive) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'placeStoryAtCoordinates',
        {'x': x, 'y': y, 'normX': x, 'normY': y},
      );
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopSession() async {
    _isSessionActive = false;
    try {
      await _channel.invokeMethod('stopSession');
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stopSession();
    await _planesController.close();
    await _statusController.close();
  }
}
