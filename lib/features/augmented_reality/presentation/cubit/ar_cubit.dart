import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:startale_mobile/features/reader/domain/repositories/reader_repository.dart';
import '../../domain/entities/ar_plane.dart';
import '../../domain/entities/ar_status_update.dart';
import '../../domain/repositories/ar_service.dart';
import 'ar_state.dart';

/// Cubit que administra el ciclo de vida y los estados de la experiencia de Realidad Aumentada (Fase 5).
class ArCubit extends Cubit<ArState> {
  final ArService _arService;
  final ReaderRepository _readerRepository;

  StreamSubscription<List<ArPlane>>? _planesSubscription;
  StreamSubscription<ArStatusUpdate>? _statusSubscription;

  ArCubit({
    required ArService arService,
    required ReaderRepository readerRepository,
  })  : _arService = arService,
        _readerRepository = readerRepository,
        super(const ArState());

  /// Realiza la verificación previa de compatibilidad del hardware con ARCore.
  Future<bool> checkCompatibility() async {
    emit(state.copyWith(status: ArStatus.checkingCompatibility, clearError: true));
    try {
      final info = await _arService.checkCompatibility();
      if (!isClosed) {
        emit(state.copyWith(
          status: info.isSupported ? ArStatus.initial : ArStatus.error,
          compatibilityInfo: info,
          errorMessage: info.isSupported ? null : info.userMessage,
        ));
      }
      return info.isSupported;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ArStatus.error,
          errorMessage: 'Error al comprobar compatibilidad de Realidad Aumentada: $e',
        ));
      }
      return false;
    }
  }

  /// Inicia el flujo completo de Realidad Aumentada para un cuento específico.
  Future<bool> startArExperience({
    required String storyId,
    int initialPageIndex = 0,
  }) async {
    emit(state.copyWith(
      status: ArStatus.checkingCompatibility,
      storyId: storyId,
      currentPageIndex: initialPageIndex,
      clearError: true,
      clearSelection: true,
    ));

    try {
      // 1. Verificación obligatoria de compatibilidad
      final compatibility = await _arService.checkCompatibility();
      emit(state.copyWith(compatibilityInfo: compatibility));

      if (!compatibility.isSupported) {
        emit(state.copyWith(
          status: ArStatus.error,
          errorMessage: compatibility.userMessage,
        ));
        return false;
      }

      // 2. Carga de datos del cuento en segundo plano
      final story = await _readerRepository.getStory(storyId);
      final pages = await _readerRepository.getStoryPages(storyId);
      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      emit(state.copyWith(
        story: story,
        pages: pages,
        currentPageIndex: initialPageIndex.clamp(0, pages.isEmpty ? 0 : pages.length - 1),
      ));

      // 3. Comprobación y solicitud de permiso de cámara
      emit(state.copyWith(status: ArStatus.requestingPermission));
      final hasPermission = await _arService.hasCameraPermission();
      if (!hasPermission) {
        final granted = await _arService.requestCameraPermission();
        if (!granted) {
          emit(state.copyWith(
            status: ArStatus.error,
            errorMessage: 'Se requiere permiso de acceso a la cámara para la Realidad Aumentada.',
          ));
          return false;
        }
      }

      // 4. Inicialización de sesión nativa
      emit(state.copyWith(status: ArStatus.initializingSession));
      await _arService.initializeSession();

      // 5. Suscripción a detección continua de superficies planas y telemetría de tracking
      await _planesSubscription?.cancel();
      _planesSubscription = _arService.planesStream.listen((planes) {
        if (!isClosed && planes.isNotEmpty) {
          final firstPlane = planes.first;
          emit(state.copyWith(
            detectedPlanes: planes,
            selectedPlane: state.selectedPlane ?? firstPlane,
            status: state.isStoryPlaced ? state.status : ArStatus.surfaceDetected,
          ));
        }
      });

      await _statusSubscription?.cancel();
      _statusSubscription = _arService.statusStream.listen((status) {
        if (!isClosed) {
          final isSurfaceReady = status.hasValidPlacementPoint || state.detectedPlanes.isNotEmpty;
          emit(state.copyWith(
            cameraTrackingState: status.cameraTrackingState,
            trackingFailureReason: status.trackingFailureReason,
            frameTimestampNs: status.frameTimestampNs,
            eventsSentCount: status.eventsSentCount,
            eventsReceivedCount: status.eventsReceivedCount,
            knownPlanesCount: status.knownPlanesCount,
            validPlanesCount: status.validPlanesCount,
            nonHorizontalPlanesCount: status.nonHorizontalPlanesCount,
            pausedPlanesCount: status.pausedPlanesCount,
            subsumedPlanesCount: status.subsumedPlanesCount,
            planeDiscardReason: status.planeDiscardReason,
            hasValidPlacementPoint: status.hasValidPlacementPoint,
            hasHitAtReticle: status.hasHitAtReticle,
            placementPointType: status.placementPointType,
            hitDistanceMeters: status.hitDistanceMeters,
            anchorScreenX: status.anchorScreenX,
            anchorScreenY: status.anchorScreenY,
            anchorNormX: status.anchorNormX,
            anchorNormY: status.anchorNormY,
            anchorDistance: status.anchorDistance,
            anchorYaw: status.anchorYaw,
            anchorPitch: status.anchorPitch,
            isAnchorTracking: status.isAnchorTracking,
            isAnchorInView: status.isAnchorInView,
            viewportWidth: status.viewportWidth,
            viewportHeight: status.viewportHeight,
            lastTelemetryUpdate: DateTime.now(),
            status: state.isStoryPlaced
                ? state.status
                : (isSurfaceReady ? ArStatus.surfaceDetected : ArStatus.scanningSurface),
          ));
        }
      });

      // 6. Iniciar escaneo de superficie
      emit(state.copyWith(status: ArStatus.scanningSurface));
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ArStatus.error,
          errorMessage: 'No fue posible iniciar la experiencia AR: $e',
        ));
      }
      return false;
    }
  }

  /// Coloca virtualmente el cuento anclado a la superficie plana detectada o retícula espacial.
  Future<bool> placeStory() async {
    final plane = state.selectedPlane ?? (state.detectedPlanes.isNotEmpty ? state.detectedPlanes.first : null);
    final targetPlaneId = plane?.id ?? 'reticle-anchor';

    try {
      final success = await _arService.placeStoryAnchor(targetPlaneId);
      if (success && !isClosed) {
        emit(state.copyWith(
          status: ArStatus.storyPlaced,
          placedPlaneId: targetPlaneId,
          selectedPlane: plane,
          clearError: true,
        ));
        return true;
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ArStatus.error,
          errorMessage: 'No fue posible anclar el cuento en la superficie: $e',
        ));
      }
      return false;
    }
  }

  /// Coloca el cuento en una coordenada de pantalla específica seleccionada por el usuario mediante tap.
  Future<bool> placeStoryAtCoordinates(double x, double y) async {
    try {
      final success = await _arService.placeStoryAtCoordinates(x, y);
      if (success && !isClosed) {
        emit(state.copyWith(
          status: ArStatus.storyPlaced,
          placedPlaneId: 'tap-anchor',
          clearError: true,
        ));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Permite volver al modo de detección para recolocar el cuento en otra superficie plana.
  void repositionStory() {
    emit(state.copyWith(
      status: state.detectedPlanes.isNotEmpty
          ? ArStatus.surfaceDetected
          : ArStatus.scanningSurface,
    ));
  }

  /// Ajusta el escalado (tamaño) del cuento 3D colocado en el espacio.
  void setCardScale(double scale) {
    final clamped = scale.clamp(0.65, 1.45);
    emit(state.copyWith(cardScale: clamped));
  }

  /// Ajusta la rotación ligera del cuento 3D para adaptarlo a la perspectiva del usuario.
  void setCardRotation({double? rotationY, double? rotationX}) {
    emit(state.copyWith(
      cardRotationY: rotationY != null ? rotationY.clamp(-0.45, 0.45) : state.cardRotationY,
      cardRotationX: rotationX != null ? rotationX.clamp(-0.35, 0.35) : state.cardRotationX,
    ));
  }

  /// Restablece la orientación y el tamaño del panel AR a sus valores predeterminados.
  void resetCardTransform() {
    emit(state.copyWith(resetTransform: true));
  }

  /// Selecciona una superficie alternativa entre las detectadas.
  void selectPlane(ArPlane plane) {
    emit(state.copyWith(selectedPlane: plane));
  }

  /// Avanza a la siguiente página del cuento en Realidad Aumentada.
  void nextPage() {
    if (state.hasNextPage) {
      emit(state.copyWith(currentPageIndex: state.currentPageIndex + 1));
    }
  }

  /// Retrocede a la página anterior del cuento en Realidad Aumentada.
  void previousPage() {
    if (state.hasPreviousPage) {
      emit(state.copyWith(currentPageIndex: state.currentPageIndex - 1));
    }
  }

  /// Finaliza la sesión de Realidad Aumentada y libera la cámara.
  Future<void> exitAr() async {
    await _planesSubscription?.cancel();
    _planesSubscription = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _arService.stopSession();
    if (!isClosed) {
      emit(state.copyWith(
        status: ArStatus.sessionEnded,
        clearSelection: true,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _planesSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _arService.stopSession();
    return super.close();
  }
}
