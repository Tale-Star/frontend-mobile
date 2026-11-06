import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/router/route_names.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_state.dart';
import 'package:startale_mobile/features/music/presentation/widgets/persistent_mini_player.dart';

class MockMusicPlayerCubit extends Mock implements MusicPlayerCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMusicPlayerCubit mockMusicPlayerCubit;

  const tTrack = MusicTrack(
    id: 'track-test-1',
    resourceId: 'res-mus-1',
    name: 'Sinfonía del Espacio',
    description: 'Pista de prueba',
    resourceUrl: '/api/v1/media/assets/res-mus-1',
    mediaType: 'audio/flac',
    favorite: false,
    duration: Duration(minutes: 3),
  );

  setUp(() {
    mockMusicPlayerCubit = MockMusicPlayerCubit();
    when(() => mockMusicPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockMusicPlayerCubit.togglePlayPause()).thenAnswer((_) async {});
    when(() => mockMusicPlayerCubit.stop()).thenAnswer((_) async {});
  });

  Widget buildTestWidget({required Widget child}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<MusicPlayerCubit>.value(
            value: mockMusicPlayerCubit,
            child: Scaffold(body: child),
          ),
        ),
        GoRoute(
          path: RouteNames.musicPlayerPath,
          name: RouteNames.musicPlayer,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pantalla Reproductor Completo')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  group('PersistentMiniPlayer Widget', () {
    testWidgets('permanece oculto cuando no hay pista activa', (tester) async {
      when(() => mockMusicPlayerCubit.state).thenReturn(const MusicPlayerState());

      await tester.pumpWidget(buildTestWidget(child: const PersistentMiniPlayer()));
      await tester.pump();

      expect(find.byKey(const Key('mini_player_title')), findsNothing);
      expect(find.byKey(const Key('mini_player_play_pause_button')), findsNothing);
    });

    testWidgets('se muestra con título, formato FLAC y barra de progreso al estar activo', (tester) async {
      when(() => mockMusicPlayerCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
          position: Duration(seconds: 45),
          duration: Duration(seconds: 180),
        ),
      );

      await tester.pumpWidget(buildTestWidget(child: const PersistentMiniPlayer()));
      await tester.pump();

      expect(find.text('Sinfonía del Espacio'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.byKey(const Key('mini_player_progress')), findsOneWidget);
      expect(find.byKey(const Key('mini_player_play_pause_button')), findsOneWidget);
    });

    testWidgets('botón reproducir/pausar invoca togglePlayPause en el cubit', (tester) async {
      when(() => mockMusicPlayerCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
        ),
      );

      await tester.pumpWidget(buildTestWidget(child: const PersistentMiniPlayer()));
      await tester.pump();

      final playPauseBtn = find.byKey(const Key('mini_player_play_pause_button'));
      expect(playPauseBtn, findsOneWidget);

      await tester.tap(playPauseBtn);
      await tester.pump();

      verify(() => mockMusicPlayerCubit.togglePlayPause()).called(1);
    });

    testWidgets('botón cerrar invoca stop en el cubit', (tester) async {
      when(() => mockMusicPlayerCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.paused,
        ),
      );

      await tester.pumpWidget(buildTestWidget(child: const PersistentMiniPlayer()));
      await tester.pump();

      final closeBtn = find.byKey(const Key('mini_player_close_button'));
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pump();

      verify(() => mockMusicPlayerCubit.stop()).called(1);
    });

    testWidgets('tocar sobre el cuerpo navega a la pantalla completa del reproductor', (tester) async {
      when(() => mockMusicPlayerCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
        ),
      );

      await tester.pumpWidget(buildTestWidget(child: const PersistentMiniPlayer()));
      await tester.pump();

      final tapArea = find.byKey(const Key('mini_player_tap_area'));
      await tester.tap(tapArea);
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Reproductor Completo'), findsOneWidget);
    });
  });
}

