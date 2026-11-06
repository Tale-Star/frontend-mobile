import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';

/// Implementación concreta de [AudioPlayerService] utilizando el motor `just_audio` y `audio_session`.
class JustAudioPlayerServiceImpl implements AudioPlayerService {
  final AudioPlayer _player;
  bool _isSessionConfigured = false;

  JustAudioPlayerServiceImpl({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> _ensureAudioSession() async {
    if (_isSessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _isSessionConfigured = true;
    } catch (e) {
      debugPrint('[JustAudioPlayerServiceImpl] No se pudo configurar AudioSession: $e');
    }
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<AudioPlaybackStatus> get playbackStatusStream {
    return _player.playerStateStream.map((playerState) {
      final processingState = playerState.processingState;
      final playing = playerState.playing;

      switch (processingState) {
        case ProcessingState.idle:
          return AudioPlaybackStatus.idle;
        case ProcessingState.loading:
          return AudioPlaybackStatus.loading;
        case ProcessingState.buffering:
          return AudioPlaybackStatus.buffering;
        case ProcessingState.ready:
          return playing ? AudioPlaybackStatus.playing : AudioPlaybackStatus.paused;
        case ProcessingState.completed:
          return AudioPlaybackStatus.completed;
      }
    });
  }

  @override
  Duration get currentPosition => _player.position;

  @override
  Duration? get currentDuration => _player.duration;

  @override
  bool get isPlaying => _player.playing;

  @override
  Future<Duration?> loadUrl(String url, {Map<String, String>? headers}) async {
    await _ensureAudioSession();
    return await _player.setUrl(url, headers: headers);
  }

  @override
  Future<Duration?> loadAsset(String assetPath) async {
    await _ensureAudioSession();
    return await _player.setAsset(assetPath);
  }

  @override
  Future<void> play() async {
    await _ensureAudioSession();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

