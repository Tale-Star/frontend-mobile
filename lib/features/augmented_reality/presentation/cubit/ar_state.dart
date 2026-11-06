import 'package:equatable/equatable.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';
import '../../domain/entities/ar_compatibility.dart';
import '../../domain/entities/ar_plane.dart';

/// Ciclo de vida y estados posibles de la experiencia de Realidad Aumentada.
enum ArStatus {
  initial,
  checkingCompatibility,
  requestingPermission,
  initializingSession,
  scanningSurface,
  surfaceDetected,
  storyPlaced,
  error,
  sessionEnded,
}

/// Estado inmutable del BLoC/Cubit de Realidad Aumentada.
class ArState extends Equatable {
  final ArStatus status;
  final ArCompatibilityInfo? compatibilityInfo;
  final List<ArPlane> detectedPlanes;
  final ArPlane? selectedPlane;
  final String? placedPlaneId;
  final String? storyId;
  final StoryDetail? story;
  final List<StoryPageDetail> pages;
  final int currentPageIndex;
  final String? errorMessage;

  // Transformaciones espaciales interactivas del panel/tarjeta 3D del cuento
  final double cardScale;
  final double cardRotationY;
  final double cardRotationX;

  // Telemetría espacial, tracking SLAM y hit-testing de ARCore
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
  final DateTime? lastTelemetryUpdate;

  const ArState({
    this.status = ArStatus.initial,
    this.compatibilityInfo,
    this.detectedPlanes = const [],
    this.selectedPlane,
    this.placedPlaneId,
    this.storyId,
    this.story,
    this.pages = const [],
    this.currentPageIndex = 0,
    this.errorMessage,
    this.cardScale = 1.0,
    this.cardRotationY = 0.0,
    this.cardRotationX = 0.0,
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
    this.lastTelemetryUpdate,
  });

  bool get isInitial => status == ArStatus.initial;
  bool get isCheckingCompatibility => status == ArStatus.checkingCompatibility;
  bool get isRequestingPermission => status == ArStatus.requestingPermission;
  bool get isInitializingSession => status == ArStatus.initializingSession;
  bool get isScanningSurface => status == ArStatus.scanningSurface;
  bool get isSurfaceDetected => status == ArStatus.surfaceDetected;
  bool get isStoryPlaced => status == ArStatus.storyPlaced;
  bool get isError => status == ArStatus.error;
  bool get isSessionEnded => status == ArStatus.sessionEnded;

  bool get canPlaceStory =>
      hasValidPlacementPoint || selectedPlane != null || detectedPlanes.isNotEmpty;
  bool get isCameraTracking => cameraTrackingState == 'TRACKING';
  bool get isConfirmedPlacement => placementPointType == 'CONFIRMED_PLANE';
  bool get isInstantPlacement => placementPointType == 'INSTANT_PLACEMENT';
  bool get hasPages => pages.isNotEmpty;

  StoryPageDetail? get currentPage =>
      hasPages && currentPageIndex >= 0 && currentPageIndex < pages.length
          ? pages[currentPageIndex]
          : null;

  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;

  ArState copyWith({
    ArStatus? status,
    ArCompatibilityInfo? compatibilityInfo,
    List<ArPlane>? detectedPlanes,
    ArPlane? selectedPlane,
    String? placedPlaneId,
    String? storyId,
    StoryDetail? story,
    List<StoryPageDetail>? pages,
    int? currentPageIndex,
    String? errorMessage,
    double? cardScale,
    double? cardRotationY,
    double? cardRotationX,
    String? cameraTrackingState,
    String? trackingFailureReason,
    int? frameTimestampNs,
    int? eventsSentCount,
    int? eventsReceivedCount,
    int? knownPlanesCount,
    int? validPlanesCount,
    int? nonHorizontalPlanesCount,
    int? pausedPlanesCount,
    int? subsumedPlanesCount,
    String? planeDiscardReason,
    bool? hasValidPlacementPoint,
    bool? hasHitAtReticle,
    String? placementPointType,
    double? hitDistanceMeters,
    double? anchorScreenX,
    double? anchorScreenY,
    double? anchorNormX,
    double? anchorNormY,
    double? anchorDistance,
    double? anchorYaw,
    double? anchorPitch,
    bool? isAnchorTracking,
    bool? isAnchorInView,
    double? viewportWidth,
    double? viewportHeight,
    DateTime? lastTelemetryUpdate,
    bool clearError = false,
    bool clearSelection = false,
    bool resetTransform = false,
  }) {
    return ArState(
      status: status ?? this.status,
      compatibilityInfo: compatibilityInfo ?? this.compatibilityInfo,
      detectedPlanes: detectedPlanes ?? this.detectedPlanes,
      selectedPlane: clearSelection ? null : (selectedPlane ?? this.selectedPlane),
      placedPlaneId: placedPlaneId ?? this.placedPlaneId,
      storyId: storyId ?? this.storyId,
      story: story ?? this.story,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cardScale: resetTransform ? 1.0 : (cardScale ?? this.cardScale),
      cardRotationY: resetTransform ? 0.0 : (cardRotationY ?? this.cardRotationY),
      cardRotationX: resetTransform ? 0.0 : (cardRotationX ?? this.cardRotationX),
      cameraTrackingState: cameraTrackingState ?? this.cameraTrackingState,
      trackingFailureReason: trackingFailureReason ?? this.trackingFailureReason,
      frameTimestampNs: frameTimestampNs ?? this.frameTimestampNs,
      eventsSentCount: eventsSentCount ?? this.eventsSentCount,
      eventsReceivedCount: eventsReceivedCount ?? this.eventsReceivedCount,
      knownPlanesCount: knownPlanesCount ?? this.knownPlanesCount,
      validPlanesCount: validPlanesCount ?? this.validPlanesCount,
      nonHorizontalPlanesCount: nonHorizontalPlanesCount ?? this.nonHorizontalPlanesCount,
      pausedPlanesCount: pausedPlanesCount ?? this.pausedPlanesCount,
      subsumedPlanesCount: subsumedPlanesCount ?? this.subsumedPlanesCount,
      planeDiscardReason: planeDiscardReason ?? this.planeDiscardReason,
      hasValidPlacementPoint: hasValidPlacementPoint ?? this.hasValidPlacementPoint,
      hasHitAtReticle: hasHitAtReticle ?? this.hasHitAtReticle,
      placementPointType: placementPointType ?? this.placementPointType,
      hitDistanceMeters: hitDistanceMeters ?? this.hitDistanceMeters,
      anchorScreenX: anchorScreenX ?? this.anchorScreenX,
      anchorScreenY: anchorScreenY ?? this.anchorScreenY,
      anchorNormX: anchorNormX ?? this.anchorNormX,
      anchorNormY: anchorNormY ?? this.anchorNormY,
      anchorDistance: anchorDistance ?? this.anchorDistance,
      anchorYaw: anchorYaw ?? this.anchorYaw,
      anchorPitch: anchorPitch ?? this.anchorPitch,
      isAnchorTracking: isAnchorTracking ?? this.isAnchorTracking,
      isAnchorInView: isAnchorInView ?? this.isAnchorInView,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      lastTelemetryUpdate: lastTelemetryUpdate ?? this.lastTelemetryUpdate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        compatibilityInfo,
        detectedPlanes,
        selectedPlane,
        placedPlaneId,
        storyId,
        story,
        pages,
        currentPageIndex,
        errorMessage,
        cardScale,
        cardRotationY,
        cardRotationX,
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
        lastTelemetryUpdate,
      ];
}
