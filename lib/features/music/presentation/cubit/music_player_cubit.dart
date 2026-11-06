import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/services/audio_player_service.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/repositories/music_repository.dart';
import 'music_player_state.dart';

/// Cubit que controla el reproductor de pistas musicales ambientales (Fase 4).
///
/// Gestiona la reproducción en segundo plano dentro de la app, decodificación FLAC/Lossless,
/// streaming autenticado mediante JWT y persistencia visual mediante el mini-reproductor.
class MusicPlayerCubit extends Cubit<MusicPlayerState> {
  final AudioPlayerService _audioPlayerService;
  final SecureStorageService _secureStorageService;
  final MusicRepository? _musicRepository;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;
  StreamSubscription<AudioPlaybackStatus>? _statusSubscription;

  MusicPlayerCubit({
    required AudioPlayerService audioPlayerService,
    required SecureStorageService secureStorageService,
    MusicRepository? musicRepository,
  })  : _audioPlayerService = audioPlayerService,
        _secureStorageService = secureStorageService,
        _musicRepository = musicRepository,
        super(const MusicPlayerState()) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _positionSubscription = _audioPlayerService.positionStream.listen((pos) {
      if (!isClosed) {
        emit(state.copyWith(position: pos));
      }
    });

    _durationSubscription = _audioPlayerService.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });

    _bufferedPositionSubscription =
        _audioPlayerService.bufferedPositionStream.listen((bufPos) {
      if (!isClosed) {
        emit(state.copyWith(bufferedPosition: bufPos));
      }
    });

    _statusSubscription =
        _audioPlayerService.playbackStatusStream.listen((audioStatus) {
      if (isClosed) return;

      switch (audioStatus) {
        case AudioPlaybackStatus.playing:
          emit(state.copyWith(status: MusicPlayerStatus.playing, clearError: true));
          break;
        case AudioPlaybackStatus.paused:
          // Solo actualizamos a pausado si ya teníamos una pista activa
          if (state.hasTrack && state.status != MusicPlayerStatus.initial) {
            emit(state.copyWith(status: MusicPlayerStatus.paused));
          }
          break;
        case AudioPlaybackStatus.buffering:
          emit(state.copyWith(status: MusicPlayerStatus.buffering));
          break;
        case AudioPlaybackStatus.loading:
          emit(state.copyWith(status: MusicPlayerStatus.loading));
          break;
        case AudioPlaybackStatus.completed:
          emit(state.copyWith(
            status: MusicPlayerStatus.completed,
            position: state.duration,
          ));
          break;
        case AudioPlaybackStatus.error:
          emit(state.copyWith(
            status: MusicPlayerStatus.error,
            errorMessage: 'Ocurrió un error al decodificar la pista de audio.',
          ));
          break;
        case AudioPlaybackStatus.idle:
          break;
      }
    });
  }

  /// Inicia la reproducción de una pista musical específica.
  Future<void> playTrack(MusicTrack track) async {
    // Si la misma pista ya está pausada, simplemente reanudar
    if (state.currentTrack?.id == track.id && state.isPaused) {
      await resume();
      return;
    }

    emit(state.copyWith(
      status: MusicPlayerStatus.loading,
      currentTrack: track,
      position: Duration.zero,
      duration: track.duration ?? Duration.zero,
      clearError: true,
    ));

    try {
      final localPath = track.localAssetPath;
      if (localPath != null && localPath.isNotEmpty) {
        // Modo Demostración / Offline
        final loadedDuration = await _audioPlayerService.loadAsset(localPath);
        if (loadedDuration != null) {
          emit(state.copyWith(duration: loadedDuration));
        }
      } else {
        // Streaming autenticado con backend de Tale Star
        final fullUrl = _resolveUrl(track.resourceUrl);
        final token = await _secureStorageService.getToken();
        final headers = <String, String>{};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }

        final loadedDuration = await _audioPlayerService.loadUrl(fullUrl, headers: headers);
        if (loadedDuration != null) {
          emit(state.copyWith(duration: loadedDuration));
        }
      }

      await _audioPlayerService.play();
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: MusicPlayerStatus.error,
          errorMessage: 'No fue posible reproducir "${track.name}": $e',
        ));
      }
    }
  }

  /// Alterna entre reproducir y pausar la pista actual.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else if (state.isPaused || state.isCompleted) {
      await resume();
    } else if (state.currentTrack != null) {
      await playTrack(state.currentTrack!);
    }
  }

  /// Pausa la reproducción actual.
  Future<void> pause() async {
    try {
      await _audioPlayerService.pause();
      if (!isClosed) {
        emit(state.copyWith(status: MusicPlayerStatus.paused));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: MusicPlayerStatus.error,
          errorMessage: 'Error al pausar: $e',
        ));
      }
    }
  }

  /// Reanuda la reproducción.
  Future<void> resume() async {
    try {
      if (state.isCompleted) {
        await _audioPlayerService.seek(Duration.zero);
      }
      await _audioPlayerService.play();
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: MusicPlayerStatus.error,
          errorMessage: 'Error al reanudar la reproducción: $e',
        ));
      }
    }
  }

  /// Busca una posición específica dentro de la pista.
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayerService.seek(position);
      if (!isClosed) {
        emit(state.copyWith(position: position));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: MusicPlayerStatus.error,
          errorMessage: 'Error al desplazar la pista: $e',
        ));
      }
    }
  }

  /// Desplaza la reproducción relativamente hacia adelante o atrás (ej. +/- 10s).
  Future<void> seekRelative(Duration offset) async {
    var target = state.position + offset;
    if (target < Duration.zero) {
      target = Duration.zero;
    } else if (state.duration > Duration.zero && target > state.duration) {
      target = state.duration;
    }
    await seek(target);
  }

  /// Alterna el estado de favorito de la pista actual.
  Future<void> toggleFavorite() async {
    final track = state.currentTrack;
    if (track == null || _musicRepository == null) return;

    try {
      final updatedTrack = await _musicRepository.toggleFavorite(track);
      if (!isClosed) {
        emit(state.copyWith(currentTrack: updatedTrack));
      }
    } catch (e) {
      // No interrumpimos la reproducción por fallo al alternar favorito
    }
  }

  /// Detiene la reproducción y reinicia la pista.
  Future<void> stop() async {
    try {
      await _audioPlayerService.stop();
      if (!isClosed) {
        emit(state.copyWith(
          status: MusicPlayerStatus.initial,
          position: Duration.zero,
        ));
      }
    } catch (e) {
      // Ignorar errores al detener
    }
  }

  /// Limpia la sesión de reproducción por completo (al cerrar sesión o invalidar credenciales).
  Future<void> clearSession() async {
    try {
      await _audioPlayerService.stop();
    } catch (_) {}
    if (!isClosed) {
      emit(const MusicPlayerState());
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConfig.instance.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  @override
  Future<void> close() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferedPositionSubscription?.cancel();
    await _statusSubscription?.cancel();
    return super.close();
  }
}

