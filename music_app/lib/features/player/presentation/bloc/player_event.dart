import 'package:equatable/equatable.dart';
import '../../../library/domain/entities/track.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayTrack extends PlayerEvent {
  final Track track;
  final String bucketUrl;
  final bool preserveQueue;

  const PlayTrack(this.track, this.bucketUrl, {this.preserveQueue = false});

  @override
  List<Object?> get props => [track, bucketUrl, preserveQueue];
}

class PlayQueue extends PlayerEvent {
  final List<Track> queue;
  final int startIndex;
  final String bucketUrl;

  const PlayQueue(this.queue, {this.startIndex = 0, required this.bucketUrl});

  @override
  List<Object?> get props => [queue, startIndex, bucketUrl];
}

class PlayPause extends PlayerEvent {
  const PlayPause();
}

class Stop extends PlayerEvent {
  const Stop();
}

class Seek extends PlayerEvent {
  final Duration position;

  const Seek(this.position);

  @override
  List<Object?> get props => [position];
}

class SkipNext extends PlayerEvent {
  const SkipNext();
}

class SkipPrevious extends PlayerEvent {
  const SkipPrevious();
}

class UpdatePosition extends PlayerEvent {
  final Duration position;

  const UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class UpdateDuration extends PlayerEvent {
  final Duration duration;

  const UpdateDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class UpdatePlayerState extends PlayerEvent {
  final bool isPlaying;

  const UpdatePlayerState(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class PlayerError extends PlayerEvent {
  final String message;

  const PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateCurrentIndex extends PlayerEvent {
  final int index;

  const UpdateCurrentIndex(this.index);

  @override
  List<Object?> get props => [index];
}
