import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_compatibility.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_plane.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_status_update.dart';
import 'package:startale_mobile/features/augmented_reality/domain/repositories/ar_service.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_cubit.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_state.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';
import 'package:startale_mobile/features/reader/domain/repositories/reader_repository.dart';

class MockArService extends Mock implements ArService {}
class MockReaderRepository extends Mock implements ReaderRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArService mockArService;
  late MockReaderRepository mockReaderRepository;
  late StreamController<List<ArPlane>> planesController;
  late StreamController<ArStatusUpdate> statusController;

  const tStoryId = 'story-ar-1';

  final tStory = StoryDetail(
    id: tStoryId,
    title: 'Viaje a las Estrellas',
    description: 'Cuento interactivo para AR',
    createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
  );

  final tPages = [
    StoryPageDetail(
      id: 'p-1',
      storyId: tStoryId,
      pageNumber: 1,
      action: 'Inicio del viaje',
      text: 'El cohete se prepara para el despegue cósmico.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
    ),
    StoryPageDetail(
      id: 'p-2',
      storyId: tStoryId,
      pageNumber: 2,
      action: 'Llegada a la Luna',
      text: 'Alcanzaron el mar de la tranquilidad.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-11-01T10:01:00Z'),
      updatedAt: DateTime.parse('2026-11-01T10:01:00Z'),
    ),
  ];

  const tCompatibleInfo = ArCompatibilityInfo(
    isSupported: true,
    availability: ArCoreAvailability.supportedInstalled,
    deviceModel: 'Pixel 8',
    userMessage: 'Dispositivo compatible',
  );

  const tIncompatibleInfo = ArCompatibilityInfo(
    isSupported: false,
    availability: ArCoreAvailability.unsupportedDeviceNotCapable,
    deviceModel: 'Xiaomi Redmi Note 13 4G (23129RA5FL)',
    userMessage: 'Tu dispositivo no cuenta con la certificación oficial de Google ARCore.',
  );

  const tPlane = ArPlane(
    id: 'plane-mesa-01',
    type: ArPlaneType.horizontalUpward,
    extentX: 1.0,
    extentZ: 0.8,
  );

  setUp(() {
    mockArService = MockArService();
    mockReaderRepository = MockReaderRepository();
    planesController = StreamController<List<ArPlane>>.broadcast();
    statusController = StreamController<ArStatusUpdate>.broadcast();

    when(() => mockArService.planesStream).thenAnswer((_) => planesController.stream);
    when(() => mockArService.statusStream).thenAnswer((_) => statusController.stream);
    when(() => mockArService.checkCompatibility()).thenAnswer((_) async => tCompatibleInfo);
    when(() => mockArService.hasCameraPermission()).thenAnswer((_) async => true);
    when(() => mockArService.requestCameraPermission()).thenAnswer((_) async => true);
    when(() => mockArService.initializeSession()).thenAnswer((_) async {});
    when(() => mockArService.placeStoryAnchor(any())).thenAnswer((_) async => true);
    when(() => mockArService.placeStoryAtCoordinates(any(), any())).thenAnswer((_) async => true);
    when(() => mockArService.stopSession()).thenAnswer((_) async {});

    when(() => mockReaderRepository.getStory(tStoryId)).thenAnswer((_) async => tStory);
    when(() => mockReaderRepository.getStoryPages(tStoryId)).thenAnswer((_) async => tPages);
  });

  tearDown(() async {
    await planesController.close();
    await statusController.close();
  });

  ArCubit buildCubit() {
    return ArCubit(
      arService: mockArService,
      readerRepository: mockReaderRepository,
    );
  }

  group('ArCubit', () {
    test('estado inicial está vacío y sin superficies ni cuento cargado', () {
      final cubit = buildCubit();
      expect(cubit.state, const ArState());
      expect(cubit.state.isInitial, isTrue);
      expect(cubit.state.detectedPlanes, isEmpty);
      cubit.close();
    });

    test('checkCompatibility con dispositivo compatible retorna true', () async {
      final cubit = buildCubit();

      final result = await cubit.checkCompatibility();

      expect(result, isTrue);
      expect(cubit.state.compatibilityInfo, equals(tCompatibleInfo));
      expect(cubit.state.status, ArStatus.initial);

      cubit.close();
    });

    test('checkCompatibility con dispositivo incompatible emite ArStatus.error con mensaje amigable', () async {
      when(() => mockArService.checkCompatibility()).thenAnswer((_) async => tIncompatibleInfo);

      final cubit = buildCubit();
      final result = await cubit.checkCompatibility();

      expect(result, isFalse);
      expect(cubit.state.status, ArStatus.error);
      expect(cubit.state.errorMessage, contains('no cuenta con la certificación oficial'));

      cubit.close();
    });

    test('startArExperience en hardware incompatible no solicita permisos ni inicializa ARCore', () async {
      when(() => mockArService.checkCompatibility()).thenAnswer((_) async => tIncompatibleInfo);

      final cubit = buildCubit();
      final success = await cubit.startArExperience(storyId: tStoryId);

      expect(success, isFalse);
      expect(cubit.state.status, ArStatus.error);
      verifyNever(() => mockArService.requestCameraPermission());
      verifyNever(() => mockArService.initializeSession());

      cubit.close();
    });

    test('startArExperience cuando se rechaza permiso de cámara emite ArStatus.error', () async {
      when(() => mockArService.hasCameraPermission()).thenAnswer((_) async => false);
      when(() => mockArService.requestCameraPermission()).thenAnswer((_) async => false);

      final cubit = buildCubit();
      final success = await cubit.startArExperience(storyId: tStoryId);

      expect(success, isFalse);
      expect(cubit.state.status, ArStatus.error);
      expect(cubit.state.errorMessage, contains('permiso de acceso a la cámara'));
      verifyNever(() => mockArService.initializeSession());

      cubit.close();
    });

    test('startArExperience exitoso inicializa sesión y activa escaneo de superficies', () async {
      final cubit = buildCubit();

      final success = await cubit.startArExperience(storyId: tStoryId);

      expect(success, isTrue);
      expect(cubit.state.status, ArStatus.scanningSurface);
      expect(cubit.state.story, equals(tStory));
      expect(cubit.state.pages.length, equals(2));
      verify(() => mockArService.initializeSession()).called(1);

      cubit.close();
    });

    test('detección de planos en el stream transiciona a surfaceDetected', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      planesController.add([tPlane]);
      await pumpEventQueue();

      expect(cubit.state.status, ArStatus.surfaceDetected);
      expect(cubit.state.detectedPlanes.length, equals(1));
      expect(cubit.state.selectedPlane, equals(tPlane));
      expect(cubit.state.canPlaceStory, isTrue);

      cubit.close();
    });

    test('placeStory ancla el cuento sobre la superficie detectada y pasa a storyPlaced', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      planesController.add([tPlane]);
      await pumpEventQueue();

      final placed = await cubit.placeStory();

      expect(placed, isTrue);
      expect(cubit.state.status, ArStatus.storyPlaced);
      expect(cubit.state.placedPlaneId, equals('plane-mesa-01'));
      verify(() => mockArService.placeStoryAnchor('plane-mesa-01')).called(1);

      cubit.close();
    });

    test('nextPage y previousPage controlan la paginación respetando límites', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      expect(cubit.state.currentPageIndex, 0);
      expect(cubit.state.hasPreviousPage, isFalse);
      expect(cubit.state.hasNextPage, isTrue);

      cubit.nextPage();
      expect(cubit.state.currentPageIndex, 1);
      expect(cubit.state.hasPreviousPage, isTrue);
      expect(cubit.state.hasNextPage, isFalse);

      // Intentar avanzar más allá de la última página no cambia el índice
      cubit.nextPage();
      expect(cubit.state.currentPageIndex, 1);

      cubit.previousPage();
      expect(cubit.state.currentPageIndex, 0);

      // Intentar retroceder más allá de la primera página no cambia el índice
      cubit.previousPage();
      expect(cubit.state.currentPageIndex, 0);

      cubit.close();
    });

    test('exitAr detiene la sesión nativa y emite sessionEnded', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      await cubit.exitAr();

      verify(() => mockArService.stopSession()).called(1);
      expect(cubit.state.status, ArStatus.sessionEnded);

      cubit.close();
    });

    test('telemetría de tracking activo actualiza estado y habilita colocación ante hit en retícula', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      statusController.add(const ArStatusUpdate(
        sessionState: 'ACTIVE',
        cameraTrackingState: 'TRACKING',
        trackingFailureReason: 'NONE',
        knownPlanesCount: 1,
        validPlanesCount: 1,
        hasValidPlacementPoint: true,
        hasHitAtReticle: true,
        placementPointType: 'CONFIRMED_PLANE',
        hitDistanceMeters: 0.95,
      ));
      await pumpEventQueue();

      expect(cubit.state.isCameraTracking, isTrue);
      expect(cubit.state.hasValidPlacementPoint, isTrue);
      expect(cubit.state.hasHitAtReticle, isTrue);
      expect(cubit.state.placementPointType, equals('CONFIRMED_PLANE'));
      expect(cubit.state.canPlaceStory, isTrue);
      expect(cubit.state.status, equals(ArStatus.surfaceDetected));

      cubit.close();
    });

    test('telemetría de cámara pausada actualiza trackingFailureReason', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      statusController.add(const ArStatusUpdate(
        sessionState: 'ACTIVE',
        cameraTrackingState: 'PAUSED',
        trackingFailureReason: 'EXCESSIVE_MOTION',
        hasValidPlacementPoint: false,
      ));
      await pumpEventQueue();

      expect(cubit.state.isCameraTracking, isFalse);
      expect(cubit.state.trackingFailureReason, equals('EXCESSIVE_MOTION'));
      expect(cubit.state.hasValidPlacementPoint, isFalse);

      cubit.close();
    });

    test('placeStoryAtCoordinates ancla cuento en coordenadas de pantalla', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      final placed = await cubit.placeStoryAtCoordinates(400.0, 800.0);

      expect(placed, isTrue);
      expect(cubit.state.status, ArStatus.storyPlaced);
      expect(cubit.state.placedPlaneId, equals('tap-anchor'));
      verify(() => mockArService.placeStoryAtCoordinates(400.0, 800.0)).called(1);

      cubit.close();
    });

    test('repositionStory regresa a surfaceDetected si hay planos o a scanningSurface', () async {
      final cubit = buildCubit();
      await cubit.startArExperience(storyId: tStoryId);

      planesController.add([tPlane]);
      await pumpEventQueue();
      await cubit.placeStory();
      expect(cubit.state.isStoryPlaced, isTrue);

      cubit.repositionStory();
      expect(cubit.state.isSurfaceDetected, isTrue);
      expect(cubit.state.pages.length, equals(2));

      cubit.close();
    });
  });
}

