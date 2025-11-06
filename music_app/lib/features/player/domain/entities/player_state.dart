import 'package:equatable/equatable.dart';
import '../../../library/domain/entities/track.dart';

enum PlaybackStatus {
  stopped,
  playing,
  paused,
  buffering,
  loading,
  error,
}

class AudioPlayerState extends Equatable {
  final Track? currentTrack;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final List<Track> queue;
  final int currentIndex;

  const AudioPlayerState({
    this.currentTrack,
    this.status = PlaybackStatus.stopped,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.queue = const [],
    this.currentIndex = 0,
  });

  AudioPlayerState copyWith({
    Track? currentTrack,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    List<Track>? queue,
    int? currentIndex,
  }) {
    return AudioPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get hasTrack => currentTrack != null;

  @override
  List<Object?> get props => [
        currentTrack,
        status,
        position,
        duration,
        errorMessage,
        queue,
        currentIndex,
      ];
}
