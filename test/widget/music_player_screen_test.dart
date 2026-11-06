import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_state.dart';
import 'package:startale_mobile/features/music/presentation/screens/music_player_screen.dart';
import 'package:startale_mobile/features/music/presentation/widgets/music_waveform_visualizer.dart';

class MockMusicPlayerCubit extends Mock implements MusicPlayerCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMusicPlayerCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  const tTrack = MusicTrack(
    id: 'track-screen-1',
    resourceId: 'res-mus-1',
    name: 'Sinfonía del Bosque Estelar',
    description: 'Composición mágica con arpas y flauta.',
    resourceUrl: '/api/v1/media/assets/res-mus-1',
    mediaType: 'audio/flac',
    favorite: false,
    duration: Duration(minutes: 3, seconds: 15),
  );

  setUp(() {
    mockCubit = MockMusicPlayerCubit();
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCubit.togglePlayPause()).thenAnswer((_) async {});
    when(() => mockCubit.seekRelative(any())).thenAnswer((_) async {});
    when(() => mockCubit.seek(any())).thenAnswer((_) async {});
    when(() => mockCubit.toggleFavorite()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<MusicPlayerCubit>.value(
        value: mockCubit,
        child: const MusicPlayerScreen(),
      ),
    );
  }

  group('MusicPlayerScreen Widget', () {
    testWidgets('muestra estado vacío cuando no hay pista seleccionada', (tester) async {
      when(() => mockCubit.state).thenReturn(const MusicPlayerState());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('No hay música seleccionada'), findsOneWidget);
      expect(find.byKey(const Key('player_back_button_empty')), findsOneWidget);
    });

    testWidgets('renderiza información completa de la pista, badge FLAC y visualizador', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
          position: Duration(seconds: 45),
          duration: Duration(minutes: 3, seconds: 15),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Sinfonía del Bosque Estelar'), findsOneWidget);
      expect(find.text('Composición mágica con arpas y flauta.'), findsOneWidget);
      expect(find.text('FLAC 24-bit Lossless'), findsOneWidget);
      expect(find.byType(MusicWaveformVisualizer), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('03:15'), findsOneWidget);
      expect(find.byKey(const Key('player_seek_slider')), findsOneWidget);
    });

    testWidgets('botón play/pause invoca togglePlayPause en el cubit', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final playPauseBtn = find.byKey(const Key('player_play_pause_button'));
      expect(playPauseBtn, findsOneWidget);

      await tester.tap(playPauseBtn);
      await tester.pump();

      verify(() => mockCubit.togglePlayPause()).called(1);
    });

    testWidgets('botones de adelantar y rebobinar 10s invocan seekRelative', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
          position: Duration(seconds: 30),
          duration: Duration(minutes: 3),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final rewindBtn = find.byKey(const Key('player_rewind_button'));
      final forwardBtn = find.byKey(const Key('player_forward_button'));

      await tester.tap(rewindBtn);
      await tester.pump();
      verify(() => mockCubit.seekRelative(const Duration(seconds: -10))).called(1);

      await tester.tap(forwardBtn);
      await tester.pump();
      verify(() => mockCubit.seekRelative(const Duration(seconds: 10))).called(1);
    });

    testWidgets('botón favorito invoca toggleFavorite en el cubit', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const MusicPlayerState(
          currentTrack: tTrack,
          status: MusicPlayerStatus.playing,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final favBtn = find.byKey(const Key('player_favorite_button'));
      expect(favBtn, findsOneWidget);

      await tester.tap(favBtn);
      await tester.pump();

      verify(() => mockCubit.toggleFavorite()).called(1);
    });
  });
}
