import 'dart:async';

/// Estados normalizados del servicio de reproducción de audio.
enum AudioPlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Contrato del servicio de audio para aislar `just_audio` y facilitar pruebas.
abstract class AudioPlayerService {
  /// Flujo continuo de la posición actual de reproducción.
  Stream<Duration> get positionStream;

  /// Flujo de la duración total del audio actual.
  Stream<Duration?> get durationStream;

  /// Flujo de la posición de almacenamiento en búfer.
  Stream<Duration> get bufferedPositionStream;

  /// Flujo de estados de reproducción (cargando, reproduciendo, pausado, etc.).
  Stream<AudioPlaybackStatus> get playbackStatusStream;

  /// Posición actual síncrona.
  Duration get currentPosition;

  /// Duración total actual síncrona.
  Duration? get currentDuration;

  /// Indica si el reproductor está activo y emitiendo sonido.
  bool get isPlaying;

  /// Carga una pista desde una URL remota autenticada con encabezados opcionales.
  Future<Duration?> loadUrl(String url, {Map<String, String>? headers});

  /// Carga una pista desde un recurso local del bundle de la aplicación (assets).
  Future<Duration?> loadAsset(String assetPath);

  /// Inicia o reanuda la reproducción.
  Future<void> play();

  /// Pausa la reproducción conservando la posición.
  Future<void> pause();

  /// Desplaza el cursor de reproducción a la posición solicitada.
  Future<void> seek(Duration position);

  /// Detiene la reproducción y reinicia la posición al inicio.
  Future<void> stop();

  /// Libera los recursos del reproductor y canales de audio.
  Future<void> dispose();
}

