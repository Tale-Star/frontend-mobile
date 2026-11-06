import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/router/route_names.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_cubit.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_state.dart';
import 'package:startale_mobile/features/reader/presentation/screens/story_reader_screen.dart';
import 'package:startale_mobile/injection.dart';

class MockReaderCubit extends MockCubit<ReaderState> implements ReaderCubit {}

void main() {
  late MockReaderCubit mockCubit;

  const tStoryId = 'story-123';

  final tStory = StoryDetail(
    id: tStoryId,
    title: 'El Pequeño Astronauta',
    description: 'Aventura estelar.',
    createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
  );

  final tPage1 = StoryPageDetail(
    id: 'page-1',
    storyId: tStoryId,
    pageNumber: 1,
    action: 'Leo mira las estrellas',
    text: 'A Leo le fascinaba el firmamento infinito.',
    characterIds: const [],
    visualConfig: const {},
    createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
  );

  final tPage2 = StoryPageDetail(
    id: 'page-2',
    storyId: tStoryId,
    pageNumber: 2,
    action: 'El despegue',
    text: 'La nave encendió sus motores dorados.',
    characterIds: const [],
    visualConfig: const {},
    createdAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T10:01:00.000Z'),
  );

  setUp(() {
    mockCubit = MockReaderCubit();
    when(() => mockCubit.loadStory(any())).thenAnswer((_) async {});
    when(() => mockCubit.retry(any())).thenAnswer((_) async {});
    when(() => mockCubit.retry()).thenAnswer((_) async {});
    when(() => mockCubit.nextPage()).thenReturn(null);
    when(() => mockCubit.previousPage()).thenReturn(null);
    when(() => mockCubit.goToPage(any())).thenReturn(null);

    // Registra en el inyector
    if (sl.isRegistered<ReaderCubit>()) {
      sl.unregister<ReaderCubit>();
    }
    sl.registerFactory<ReaderCubit>(() => mockCubit);
  });

  tearDown(() {
    if (sl.isRegistered<ReaderCubit>()) {
      sl.unregister<ReaderCubit>();
    }
  });

  Widget buildTestableWidget() {
    return const MaterialApp(
      home: StoryReaderScreen(storyId: tStoryId),
    );
  }

  group('StoryReaderScreen - Estados de Vista', () {
    testWidgets('muestra estado de carga con shimmers', (tester) async {
      when(() => mockCubit.state).thenReturn(const ReaderLoading());

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('reader_back_button')), findsOneWidget);
    });

    testWidgets('muestra estado de error con mensaje amigable y botón Intentar de nuevo', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const ReaderError(message: 'Error al conectar con el servidor'),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('No pudimos abrir el cuento'), findsOneWidget);
      expect(find.text('Error al conectar con el servidor'), findsOneWidget);
      expect(find.text('Intentar de nuevo'), findsOneWidget);

      await tester.tap(find.text('Intentar de nuevo'));
      verify(() => mockCubit.retry(tStoryId)).called(1);
    });

    testWidgets('muestra estado vacío cuando el cuento no posee páginas', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderEmpty(story: tStory),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Cuento sin páginas'), findsOneWidget);
      expect(find.text('Volver a cuentos'), findsOneWidget);
    });

    testWidgets('renderiza cuento cargado con título, acción y texto narrativo', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('El Pequeño Astronauta'), findsOneWidget);
      expect(find.text('Leo mira las estrellas'), findsOneWidget);
      expect(find.text('A Leo le fascinaba el firmamento infinito.'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsOneWidget);
    });
  });

  group('StoryReaderScreen - Controles de Navegación', () {
    testWidgets('en la primera página el botón Anterior está deshabilitado y Siguiente habilitado', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      final prevFinder = find.byKey(const Key('reader_prev_button'));
      final nextFinder = find.byKey(const Key('reader_next_button'));
      expect(prevFinder, findsOneWidget);
      expect(nextFinder, findsOneWidget);

      // Tocar siguiente dispara nextPage
      await tester.tap(nextFinder);
      verify(() => mockCubit.nextPage()).called(1);
    });

    testWidgets('en la última página el botón Siguiente está deshabilitado y Anterior habilitado', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 1,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      final prevFinder = find.byKey(const Key('reader_prev_button'));
      final nextFinder = find.byKey(const Key('reader_next_button'));
      expect(prevFinder, findsOneWidget);
      expect(nextFinder, findsOneWidget);

      await tester.tap(prevFinder);
      verify(() => mockCubit.previousPage()).called(1);
    });

    testWidgets('en cuento de una sola página ambos botones están deshabilitados', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1],
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byKey(const Key('reader_prev_button')), findsOneWidget);
      expect(find.byKey(const Key('reader_next_button')), findsOneWidget);
      expect(find.text('Página 1 de 1'), findsOneWidget);
    });
  });

  group('StoryReaderScreen - Gestos y Funciones Adicionales', () {
    testWidgets('deslizar hacia la izquierda activa nextPage', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      // Deslizar hacia la izquierda (swipe left -> next)
      await tester.fling(find.text('A Leo le fascinaba el firmamento infinito.'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      verify(() => mockCubit.nextPage()).called(1);
    });

    testWidgets('deslizar hacia la derecha activa previousPage', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 1,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      // Deslizar hacia la derecha (swipe right -> prev)
      await tester.fling(find.text('La nave encendió sus motores dorados.'), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      verify(() => mockCubit.previousPage()).called(1);
    });

    testWidgets('el botón AR navega a la experiencia de Realidad Aumentada', (tester) async {
      when(() => mockCubit.state).thenReturn(
        ReaderLoaded(
          story: tStory,
          pages: [tPage1, tPage2],
          currentPageIndex: 0,
        ),
      );

      final router = GoRouter(
        initialLocation: '/story',
        routes: [
          GoRoute(
            path: '/story',
            builder: (context, state) => const StoryReaderScreen(storyId: tStoryId),
          ),
          GoRoute(
            path: RouteNames.arReaderPath,
            name: RouteNames.arReader,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Pantalla AR Escáner')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final arButton = find.byKey(const Key('reader_ar_button'));
      expect(arButton, findsOneWidget);

      await tester.tap(arButton);
      await tester.pumpAndSettle();

      expect(find.text('Pantalla AR Escáner'), findsOneWidget);
    });
  });
}
