import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/config/app_config.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/features/music/data/services/audio_player_service.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';
import 'package:startale_mobile/features/music/domain/repositories/music_repository.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_state.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockMusicRepository extends Mock implements MusicRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioPlayerService mockAudioService;
  late MockSecureStorageService mockSecureStorage;
  late MockMusicRepository mockMusicRepository;
  late StreamController<Duration> positionController;
  late StreamController<Duration?> durationController;
  late StreamController<Duration> bufferedPositionController;
  late StreamController<AudioPlaybackStatus> statusController;

  const tTrackLocal = MusicTrack(
    id: 't-local-1',
    resourceId: 'res-1',
    name: 'Sinfonía Local',
    resourceUrl: '/api/v1/media/assets/res-1',
    mediaType: 'audio/flac',
    localAssetPath: 'assets/demo/demo_song.wav',
    duration: Duration(minutes: 3),
  );

  const tTrackRemote = MusicTrack(
    id: 't-remote-1',
    resourceId: 'res-2',
    name: 'Pista Remota',
    resourceUrl: '/api/v1/media/assets/res-2',
    mediaType: 'audio/flac',
    duration: Duration(minutes: 4),
  );

  setUpAll(() {
    AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://10.0.2.2:8000',
      enableDebugLogs: false,
      useMockData: false,
    );
    registerFallbackValue(tTrackLocal);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockAudioService = MockAudioPlayerService();
    mockSecureStorage = MockSecureStorageService();
    mockMusicRepository = MockMusicRepository();

    positionController = StreamController<Duration>.broadcast();
    durationController = StreamController<Duration?>.broadcast();
    bufferedPositionController = StreamController<Duration>.broadcast();
    statusController = StreamController<AudioPlaybackStatus>.broadcast();

    when(() => mockAudioService.positionStream).thenAnswer((_) => positionController.stream);
    when(() => mockAudioService.durationStream).thenAnswer((_) => durationController.stream);
    when(() => mockAudioService.bufferedPositionStream).thenAnswer((_) => bufferedPositionController.stream);
    when(() => mockAudioService.playbackStatusStream).thenAnswer((_) => statusController.stream);

    when(() => mockAudioService.currentPosition).thenReturn(Duration.zero);
    when(() => mockAudioService.currentDuration).thenReturn(Duration.zero);
    when(() => mockAudioService.isPlaying).thenReturn(false);

    when(() => mockAudioService.loadAsset(any())).thenAnswer((_) async => const Duration(minutes: 3));
    when(() => mockAudioService.loadUrl(any(), headers: any(named: 'headers'))).thenAnswer((_) async => const Duration(minutes: 4));
    when(() => mockAudioService.play()).thenAnswer((_) async {});
    when(() => mockAudioService.pause()).thenAnswer((_) async {});
    when(() => mockAudioService.seek(any())).thenAnswer((_) async {});
    when(() => mockAudioService.stop()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await positionController.close();
    await durationController.close();
    await bufferedPositionController.close();
    await statusController.close();
  });

  MusicPlayerCubit buildCubit() {
    return MusicPlayerCubit(
      audioPlayerService: mockAudioService,
      secureStorageService: mockSecureStorage,
      musicRepository: mockMusicRepository,
    );
  }

  group('MusicPlayerCubit', () {
    test('estado inicial está vacío y sin pista cargada', () {
      final cubit = buildCubit();
      expect(cubit.state, const MusicPlayerState());
      expect(cubit.state.hasTrack, isFalse);
      expect(cubit.state.isActive, isFalse);
      cubit.close();
    });

    test('playTrack con recurso local reproduce mediante loadAsset', () async {
      final cubit = buildCubit();

      await cubit.playTrack(tTrackLocal);

      verify(() => mockAudioService.loadAsset('assets/demo/demo_song.wav')).called(1);
      verify(() => mockAudioService.play()).called(1);
      verifyNever(() => mockAudioService.loadUrl(any(), headers: any(named: 'headers')));
      expect(cubit.state.currentTrack, tTrackLocal);

      cubit.close();
    });

    test('playTrack con URL remota resuelve la dirección y envía encabezado Bearer JWT', () async {
      when(() => mockSecureStorage.getToken()).thenAnswer((_) async => 'fake_jwt_token_123');

      final cubit = buildCubit();
      await cubit.playTrack(tTrackRemote);

      verify(() => mockSecureStorage.getToken()).called(1);
      verify(() => mockAudioService.loadUrl(
            'http://10.0.2.2:8000/api/v1/media/assets/res-2',
            headers: {'Authorization': 'Bearer fake_jwt_token_123'},
          )).called(1);
      verify(() => mockAudioService.play()).called(1);

      cubit.close();
    });

    test('pause y resume controlan AudioPlayerService correctamente', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      await cubit.pause();
      verify(() => mockAudioService.pause()).called(1);
      expect(cubit.state.status, MusicPlayerStatus.paused);

      await cubit.resume();
      verify(() => mockAudioService.play()).called(2);

      cubit.close();
    });

    test('togglePlayPause alterna entre pausa y reproducción', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      statusController.add(AudioPlaybackStatus.playing);
      await pumpEventQueue();
      expect(cubit.state.isPlaying, isTrue);

      await cubit.togglePlayPause();
      verify(() => mockAudioService.pause()).called(1);

      statusController.add(AudioPlaybackStatus.paused);
      await pumpEventQueue();

      await cubit.togglePlayPause();
      verify(() => mockAudioService.play()).called(2);

      cubit.close();
    });

    test('seek y seekRelative desplazan posición sin desbordar los límites', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      durationController.add(const Duration(seconds: 100));
      positionController.add(const Duration(seconds: 30));
      await pumpEventQueue();

      await cubit.seekRelative(const Duration(seconds: 10));
      verify(() => mockAudioService.seek(const Duration(seconds: 40))).called(1);

      // Rebobinar más allá de 0 debe clampear a Duration.zero
      positionController.add(const Duration(seconds: 5));
      await pumpEventQueue();
      await cubit.seekRelative(const Duration(seconds: -10));
      verify(() => mockAudioService.seek(Duration.zero)).called(1);

      cubit.close();
    });

    test('toggleFavorite invoca al repositorio y actualiza currentTrack', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      final updatedTrack = tTrackLocal.copyWith(favorite: true);
      when(() => mockMusicRepository.toggleFavorite(tTrackLocal)).thenAnswer((_) async => updatedTrack);

      await cubit.toggleFavorite();
      verify(() => mockMusicRepository.toggleFavorite(tTrackLocal)).called(1);
      expect(cubit.state.currentTrack?.favorite, isTrue);

      cubit.close();
    });

    test('stop detiene reproducción y reinicia estado a inicial', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      await cubit.stop();
      verify(() => mockAudioService.stop()).called(1);
      expect(cubit.state.status, MusicPlayerStatus.initial);
      expect(cubit.state.position, Duration.zero);

      cubit.close();
    });

    test('clearSession reinicia completamente el estado (cierre de sesión)', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      await cubit.clearSession();
      verify(() => mockAudioService.stop()).called(1);
      expect(cubit.state, const MusicPlayerState());

      cubit.close();
    });

    test('manejo de error emite MusicPlayerStatus.error si falla la carga', () async {
      when(() => mockAudioService.loadAsset(any())).thenThrow(Exception('Archivo no encontrado'));

      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      expect(cubit.state.status, MusicPlayerStatus.error);
      expect(cubit.state.errorMessage, contains('No fue posible reproducir'));

      cubit.close();
    });

    test('actualiza estado cuando AudioPlayerService emite eventos por stream', () async {
      final cubit = buildCubit();
      await cubit.playTrack(tTrackLocal);

      positionController.add(const Duration(seconds: 15));
      durationController.add(const Duration(seconds: 180));
      bufferedPositionController.add(const Duration(seconds: 45));
      statusController.add(AudioPlaybackStatus.playing);
      await pumpEventQueue();

      expect(cubit.state.position, const Duration(seconds: 15));
      expect(cubit.state.duration, const Duration(seconds: 180));
      expect(cubit.state.bufferedPosition, const Duration(seconds: 45));
      expect(cubit.state.isPlaying, isTrue);

      cubit.close();
    });
  });
}

