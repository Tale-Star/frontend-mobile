import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/router/route_names.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_cubit.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_state.dart';
import 'package:startale_mobile/features/library/presentation/screens/image_viewer_screen.dart';
import 'package:startale_mobile/features/library/presentation/screens/images_screen.dart';
import 'package:startale_mobile/features/library/presentation/screens/library_screen.dart';
import 'package:startale_mobile/features/library/presentation/screens/music_tab_screen.dart';
import 'package:startale_mobile/features/library/presentation/screens/stories_tab_screen.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_state.dart';
import 'package:startale_mobile/shared/widgets/ts_empty_state.dart';

class MockLibraryCubit extends Mock implements LibraryCubit {}
class MockMusicPlayerCubit extends Mock implements MusicPlayerCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLibraryCubit mockLibraryCubit;
  late MockMusicPlayerCubit mockMusicPlayerCubit;

  setUpAll(() {
    registerFallbackValue(
      LibraryItemEntity(
        id: '',
        type: ContentType.story,
        resourceId: '',
        name: '',
        description: '',
        favorite: false,
        resourceUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      const MusicTrack(
        id: '',
        resourceId: '',
        name: '',
        resourceUrl: '',
        mediaType: 'audio/flac',
      ),
    );
  });

  setUp(() {
    mockLibraryCubit = MockLibraryCubit();
    mockMusicPlayerCubit = MockMusicPlayerCubit();
    when(() => mockLibraryCubit.state).thenReturn(const LibraryLoaded(items: []));
    when(() => mockLibraryCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockMusicPlayerCubit.state).thenReturn(const MusicPlayerState());
    when(() => mockMusicPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockMusicPlayerCubit.playTrack(any())).thenAnswer((_) async {});
  });

  final tStory = LibraryItemEntity(
    id: 'story-1',
    type: ContentType.story,
    resourceId: 'res-s1',
    name: 'El Cohete de Cartón',
    description: 'Un viaje a la luna.',
    favorite: false,
    resourceUrl: '/api/v1/stories/res-s1',
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  final tImage = LibraryItemEntity(
    id: 'image-1',
    type: ContentType.image,
    resourceId: 'res-i1',
    name: 'Nebulosa Azul',
    description: 'Fondo estelar cósmico.',
    favorite: true,
    resourceUrl: '/api/v1/media/assets/res-i1',
    mediaType: 'image/png',
    createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T11:00:00Z'),
  );

  final tMusic = LibraryItemEntity(
    id: 'music-1',
    type: ContentType.music,
    resourceId: 'res-m1',
    name: 'Sinfonía Galáctica',
    description: 'Pista de audio relajante.',
    favorite: false,
    resourceUrl: '/api/v1/media/assets/res-m1',
    mediaType: 'audio/flac',
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  Widget buildTestWidget(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<LibraryCubit>.value(value: mockLibraryCubit),
              BlocProvider<MusicPlayerCubit>.value(value: mockMusicPlayerCubit),
            ],
            child: child,
          ),
        ),
        GoRoute(
          path: RouteNames.readerPath,
          name: RouteNames.reader,
          builder: (context, state) => Scaffold(
            body: Center(child: Text('Lector: ${state.pathParameters['storyId']}')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  group('LibraryScreen (Biblioteca General)', () {
    testWidgets('renderiza buscador, chips de filtros y tarjetas de contenidos', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStory, tImage, tMusic]),
      );

      await tester.pumpWidget(buildTestWidget(const LibraryScreen()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Todos'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Imágenes'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cuentos'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Música'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Favoritos'), findsOneWidget);

      expect(find.text('El Cohete de Cartón'), findsOneWidget);
      expect(find.text('Nebulosa Azul'), findsOneWidget);
      expect(find.text('Sinfonía Galáctica'), findsOneWidget);
    });

    testWidgets('muestra TsEmptyState cuando la biblioteca está vacía', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(const LibraryEmpty());

      await tester.pumpWidget(buildTestWidget(const LibraryScreen()));
      await tester.pump();

      expect(find.byType(TsEmptyState), findsOneWidget);
      expect(find.text('Tu biblioteca está vacía'), findsOneWidget);
    });

    testWidgets('al presionar un cuento navega al lector 2D (Fase 3)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStory]),
      );

      await tester.pumpWidget(buildTestWidget(const LibraryScreen()));
      await tester.pump();

      await tester.tap(find.text('El Cohete de Cartón'));
      await tester.pumpAndSettle();

      expect(find.text('Lector: res-s1'), findsOneWidget);
    });

    testWidgets('al presionar una música inicia reproducción con MusicPlayerCubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tMusic]),
      );

      await tester.pumpWidget(buildTestWidget(const LibraryScreen()));
      await tester.pump();

      await tester.tap(find.text('Sinfonía Galáctica'));
      await tester.pump();

      verify(() => mockMusicPlayerCubit.playTrack(any())).called(1);
    });

    testWidgets('al presionar el chip de Cuentos invoca setTypeFilter en el cubit', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStory]),
      );
      when(() => mockLibraryCubit.setTypeFilter(ContentType.story))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget(const LibraryScreen()));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilterChip, 'Cuentos'));
      await tester.pump();

      verify(() => mockLibraryCubit.setTypeFilter(ContentType.story)).called(1);
    });
  });

  group('ImagesScreen (Pestaña 1)', () {
    testWidgets('renderiza solo las imágenes de la lista', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tImage, tStory]),
      );

      await tester.pumpWidget(buildTestWidget(const ImagesScreen()));
      await tester.pump();

      expect(find.text('Nebulosa Azul'), findsOneWidget);
      expect(find.text('El Cohete de Cartón'), findsNothing);
    });
  });

  group('StoriesTabScreen (Pestaña 2)', () {
    testWidgets('renderiza cuentos y navega al lector 2D al tocar uno', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStory]),
      );

      await tester.pumpWidget(buildTestWidget(const StoriesTabScreen()));
      await tester.pump();

      expect(find.text('El Cohete de Cartón'), findsOneWidget);

      await tester.tap(find.text('El Cohete de Cartón'));
      await tester.pumpAndSettle();

      expect(find.text('Lector: res-s1'), findsOneWidget);
    });
  });

  group('MusicTabScreen (Pestaña 3)', () {
    testWidgets('renderiza música e inicia reproducción al tocar una pista', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tMusic]),
      );

      await tester.pumpWidget(buildTestWidget(const MusicTabScreen()));
      await tester.pump();

      expect(find.text('Sinfonía Galáctica'), findsOneWidget);

      await tester.tap(find.text('Sinfonía Galáctica'));
      await tester.pump();

      verify(() => mockMusicPlayerCubit.playTrack(any())).called(1);
    });
  });

  group('ImageViewerScreen (Pantalla Completa)', () {
    testWidgets('renderiza título y botón de favorito interactivo', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tImage]),
      );
      when(() => mockLibraryCubit.toggleFavorite(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          ImageViewerScreen(
            imageId: tImage.id,
            initialItem: tImage,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nebulosa Azul'), findsOneWidget);
      final favButton = find.byKey(const Key('viewer_favorite_button'));
      expect(favButton, findsOneWidget);

      await tester.tap(favButton);
      await tester.pump();

      verify(() => mockLibraryCubit.toggleFavorite(any())).called(1);
    });
  });
}
