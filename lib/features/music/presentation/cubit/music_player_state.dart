import 'package:equatable/equatable.dart';
import '../../domain/entities/music_track.dart';

/// Estados tipados del reproductor musical.
enum MusicPlayerStatus {
  initial,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

/// Estado inmutable del reproductor musical de Tale Star.
class MusicPlayerState extends Equatable {
  final MusicTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final MusicPlayerStatus status;
  final String? errorMessage;

  const MusicPlayerState({
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.status = MusicPlayerStatus.initial,
    this.errorMessage,
  });

  bool get isInitial => status == MusicPlayerStatus.initial;
  bool get isLoading => status == MusicPlayerStatus.loading;
  bool get isPlaying => status == MusicPlayerStatus.playing;
  bool get isPaused => status == MusicPlayerStatus.paused;
  bool get isBuffering => status == MusicPlayerStatus.buffering;
  bool get isCompleted => status == MusicPlayerStatus.completed;
  bool get hasError => status == MusicPlayerStatus.error;
  bool get hasTrack => currentTrack != null;
  bool get isActive => currentTrack != null && status != MusicPlayerStatus.initial;

  /// Retorna el progreso relativo de 0.0 a 1.0.
  double get progressPercent {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  MusicPlayerState copyWith({
    MusicTrack? currentTrack,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    MusicPlayerStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MusicPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        position,
        duration,
        bufferedPosition,
        status,
        errorMessage,
      ];
}

