import 'package:equatable/equatable.dart';

/// Telemetría en tiempo real del subsistema ARCore emitida continuamente hacia Flutter.
class ArStatusUpdate extends Equatable {
  final String sessionState;
  final String cameraTrackingState;
  final String trackingFailureReason;
  final int frameTimestampNs;
  final int eventsSentCount;
  final int eventsReceivedCount;
  final int knownPlanesCount;
  final int validPlanesCount;
  final int nonHorizontalPlanesCount;
  final int pausedPlanesCount;
  final int subsumedPlanesCount;
  final String planeDiscardReason;
  final bool hasValidPlacementPoint;
  final bool hasHitAtReticle;
  final String placementPointType;
  final double hitDistanceMeters;
  final double anchorScreenX;
  final double anchorScreenY;
  final double anchorNormX;
  final double anchorNormY;
  final double anchorDistance;
  final double anchorYaw;
  final double anchorPitch;
  final bool isAnchorTracking;
  final bool isAnchorInView;
  final double viewportWidth;
  final double viewportHeight;

  const ArStatusUpdate({
    this.sessionState = 'ACTIVE',
    this.cameraTrackingState = 'UNKNOWN',
    this.trackingFailureReason = 'NONE',
    this.frameTimestampNs = 0,
    this.eventsSentCount = 0,
    this.eventsReceivedCount = 0,
    this.knownPlanesCount = 0,
    this.validPlanesCount = 0,
    this.nonHorizontalPlanesCount = 0,
    this.pausedPlanesCount = 0,
    this.subsumedPlanesCount = 0,
    this.planeDiscardReason = 'ARCore buscando superficies...',
    this.hasValidPlacementPoint = false,
    this.hasHitAtReticle = false,
    this.placementPointType = 'NONE',
    this.hitDistanceMeters = 0.0,
    this.anchorScreenX = 0.0,
    this.anchorScreenY = 0.0,
    this.anchorNormX = 0.5,
    this.anchorNormY = 0.5,
    this.anchorDistance = 0.0,
    this.anchorYaw = 0.0,
    this.anchorPitch = 0.0,
    this.isAnchorTracking = false,
    this.isAnchorInView = false,
    this.viewportWidth = 1080.0,
    this.viewportHeight = 2400.0,
  });

  bool get isCameraTracking => cameraTrackingState == 'TRACKING';
  bool get isConfirmedPlane => placementPointType == 'CONFIRMED_PLANE';
  bool get isInstantPlacement => placementPointType == 'INSTANT_PLACEMENT';

  @override
  List<Object?> get props => [
        sessionState,
        cameraTrackingState,
        trackingFailureReason,
        frameTimestampNs,
        eventsSentCount,
        eventsReceivedCount,
        knownPlanesCount,
        validPlanesCount,
        nonHorizontalPlanesCount,
        pausedPlanesCount,
        subsumedPlanesCount,
        planeDiscardReason,
        hasValidPlacementPoint,
        hasHitAtReticle,
        placementPointType,
        hitDistanceMeters,
        anchorScreenX,
        anchorScreenY,
        anchorNormX,
        anchorNormY,
        anchorDistance,
        anchorYaw,
        anchorPitch,
        isAnchorTracking,
        isAnchorInView,
        viewportWidth,
        viewportHeight,
      ];
}
