import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_compatibility.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_plane.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_cubit.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_state.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/screens/ar_surface_scanner_screen.dart';

class MockArCubit extends Mock implements ArCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArCubit mockArCubit;

  const tPlane = ArPlane(
    id: 'p-1',
    type: ArPlaneType.horizontalUpward,
    extentX: 1.0,
    extentZ: 1.0,
  );

  setUp(() {
    mockArCubit = MockArCubit();
    when(() => mockArCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockArCubit.startArExperience(
          storyId: any(named: 'storyId'),
          initialPageIndex: any(named: 'initialPageIndex'),
        )).thenAnswer((_) async => true);
    when(() => mockArCubit.placeStory()).thenAnswer((_) async => true);
    when(() => mockArCubit.exitAr()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<ArCubit>.value(
        value: mockArCubit,
        child: const ArSurfaceScannerScreen(storyId: 'story-1'),
      ),
    );
  }

  group('ArSurfaceScannerScreen Widget', () {
    testWidgets('muestra estado de escaneo inicial e instrucciones en español', (tester) async {
      when(() => mockArCubit.state).thenReturn(
        const ArState(status: ArStatus.scanningSurface),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Escaneando entorno...'), findsOneWidget);
      expect(find.textContaining('Mueve el teléfono lentamente'), findsOneWidget);

      final placeBtn = find.byKey(const Key('ar_place_story_button'));
      expect(placeBtn, findsOneWidget);
      // Cuando no hay plano detectado, el botón está deshabilitado
      final buttonWidget = tester.widget<ElevatedButton>(find.descendant(
        of: placeBtn,
        matching: find.byType(ElevatedButton),
      ));
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('cuando se detecta una superficie muestra el plano y habilita el botón de colocar cuento', (tester) async {
      when(() => mockArCubit.state).thenReturn(
        const ArState(
          status: ArStatus.surfaceDetected,
          detectedPlanes: [tPlane],
          selectedPlane: tPlane,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.textContaining('Superficie detectada'), findsOneWidget);
      expect(find.byKey(const Key('ar_detected_plane_visualizer')), findsOneWidget);

      final placeBtn = find.byKey(const Key('ar_place_story_button'));
      expect(placeBtn, findsOneWidget);

      await tester.tap(placeBtn);
      await tester.pump();

      verify(() => mockArCubit.placeStory()).called(1);
    });

    testWidgets('botón Salir invoca exitAr en el cubit', (tester) async {
      when(() => mockArCubit.state).thenReturn(
        const ArState(status: ArStatus.scanningSurface),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final exitBtn = find.byKey(const Key('ar_exit_button'));
      expect(exitBtn, findsOneWidget);

      await tester.tap(exitBtn);
      await tester.pump();

      verify(() => mockArCubit.exitAr()).called(1);
    });

    testWidgets('cuando el hardware es incompatible muestra diálogo informativo constructivo', (tester) async {
      final stateController = StreamController<ArState>.broadcast();
      when(() => mockArCubit.stream).thenAnswer((_) => stateController.stream);

      const errorState = ArState(
        status: ArStatus.error,
        compatibilityInfo: ArCompatibilityInfo(
          isSupported: false,
          availability: ArCoreAvailability.unsupportedDeviceNotCapable,
          deviceModel: 'Xiaomi Redmi Note 13 4G (23129RA5FL)',
          userMessage:
              'Tu dispositivo (Xiaomi Redmi Note 13 4G) no cuenta con la certificación oficial de Google ARCore.',
        ),
        errorMessage:
            'Tu dispositivo (Xiaomi Redmi Note 13 4G) no cuenta con la certificación oficial de Google ARCore.',
      );

      when(() => mockArCubit.state).thenReturn(errorState);

      await tester.pumpWidget(buildTestWidget());
      stateController.add(errorState);
      await tester.pumpAndSettle();

      expect(find.text('Realidad Aumentada no disponible'), findsOneWidget);
      expect(find.textContaining('no cuenta con la certificación oficial'), findsOneWidget);
      expect(find.byKey(const Key('ar_unsupported_dismiss_button')), findsOneWidget);

      await stateController.close();
    });
  });
}
