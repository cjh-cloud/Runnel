import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import '../../domain/entities/player_state.dart';
import 'player_event.dart';

class PlayerBloc extends Bloc<PlayerEvent, AudioPlayerState> {
  final ja.AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  String _currentBucketUrl = '';

  PlayerBloc() : _audioPlayer = ja.AudioPlayer(), super(const AudioPlayerState()) {
    on<PlayTrack>(_onPlayTrack);
    on<PlayQueue>(_onPlayQueue);
    on<PlayPause>(_onPlayPause);
    on<Stop>(_onStop);
    on<Seek>(_onSeek);
    on<SkipNext>(_onSkipNext);
    on<SkipPrevious>(_onSkipPrevious);
    on<UpdatePosition>(_onUpdatePosition);
    on<UpdateDuration>(_onUpdateDuration);
    on<UpdatePlayerState>(_onUpdatePlayerState);
    on<UpdateCurrentIndex>(_onUpdateCurrentIndex);
    on<PlayerError>(_onPlayerError);

    // Listen to audio player streams
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      add(UpdatePosition(position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        add(UpdateDuration(duration));
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      add(UpdatePlayerState(playerState.playing));
      
      // Auto-play next track when current track completes
      if (playerState.processingState == ja.ProcessingState.completed) {
        add(const SkipNext());
      }
    });

    // Listen to current index changes (from lockscreen controls)
    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index != state.currentIndex && state.queue.isNotEmpty) {
        if (index < state.queue.length) {
          add(UpdateCurrentIndex(index));
        }
      }
    });
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<AudioPlayerState> emit) async {
    try {
      _currentBucketUrl = event.bucketUrl;
      
      emit(state.copyWith(
        status: PlaybackStatus.loading,
        currentTrack: event.track,
        // Only reset queue if not preserving it
        queue: event.preserveQueue ? state.queue : [event.track],
        currentIndex: event.preserveQueue ? state.currentIndex : 0,
      ));

      final currentQueue = event.preserveQueue ? state.queue : [event.track];
      final currentIndex = event.preserveQueue ? state.currentIndex : 0;

      // Create audio sources for the entire queue
      final audioSources = <ja.AudioSource>[];
      
      for (final track in currentQueue) {
        // Use local file if downloaded, otherwise use S3 URL
        String url;
        if (track.isDownloaded && track.localPath != null) {
          // For local files, ensure we have a proper file:// URI
          final localPath = track.localPath!;
          if (localPath.startsWith('file://')) {
            url = localPath;
          } else if (localPath.startsWith('/')) {
            url = 'file://$localPath';
          } else {
            url = 'file:///$localPath';
          }
        } else {
          // Construct the S3 URL
          url = '${event.bucketUrl}/${track.s3Key}';
        }
        
        // Create MediaItem for each track
        final mediaItem = MediaItem(
          id: track.id,
          album: track.album,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
        );

        audioSources.add(
          ja.AudioSource.uri(
            Uri.parse(url),
            tag: mediaItem,
          ),
        );
      }

      // Set the entire queue as audio sources
      if (audioSources.length == 1) {
        // Single track - use setAudioSource
        await _audioPlayer.setAudioSource(audioSources[0]);
      } else {
        // Multiple tracks - create playlist
        final playlist = ja.ConcatenatingAudioSource(
          children: audioSources,
        );
        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: currentIndex,
        );
      }
      
      print('🎵 Audio queue set with ${audioSources.length} tracks, starting at index $currentIndex');
      
      // Start playing
      await _audioPlayer.play();

      emit(state.copyWith(
        status: PlaybackStatus.playing,
        currentTrack: event.track,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play track: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPlayQueue(PlayQueue event, Emitter<AudioPlayerState> emit) async {
    if (event.queue.isEmpty) return;
    
    _currentBucketUrl = event.bucketUrl;
    
    emit(state.copyWith(
      queue: event.queue,
      currentIndex: event.startIndex,
      status: PlaybackStatus.loading,
      currentTrack: event.queue[event.startIndex],
    ));
    
    try {
      // Create audio sources for the entire queue
      final audioSources = <ja.AudioSource>[];
      
      for (final track in event.queue) {
        // Use local file if downloaded, otherwise use S3 URL
        String url;
        if (track.isDownloaded && track.localPath != null) {
          final localPath = track.localPath!;
          if (localPath.startsWith('file://')) {
            url = localPath;
          } else if (localPath.startsWith('/')) {
            url = 'file://$localPath';
          } else {
            url = 'file:///$localPath';
          }
        } else {
          url = '${event.bucketUrl}/${track.s3Key}';
        }
        
        // Create MediaItem for each track
        final mediaItem = MediaItem(
          id: track.id,
          album: track.album,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
        );

        audioSources.add(
          ja.AudioSource.uri(
            Uri.parse(url),
            tag: mediaItem,
          ),
        );
      }

      // Set the entire queue
      final playlist = ja.ConcatenatingAudioSource(
        children: audioSources,
      );
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: event.startIndex,
      );
      
      print('🎵 Queue set with ${audioSources.length} tracks, starting at index ${event.startIndex}');
      
      // Start playing
      await _audioPlayer.play();

      emit(state.copyWith(
        status: PlaybackStatus.playing,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play queue: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSkipNext(SkipNext event, Emitter<AudioPlayerState> emit) async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else if (state.queue.isNotEmpty) {
        // Reached end of queue, stop playing
        await _audioPlayer.stop();
        emit(state.copyWith(status: PlaybackStatus.stopped));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to skip to next track: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSkipPrevious(SkipPrevious event, Emitter<AudioPlayerState> emit) async {
    try {
      // If more than 3 seconds into the track, restart it
      if (state.position.inSeconds > 3) {
        await _audioPlayer.seek(Duration.zero);
        return;
      }
      
      // Otherwise go to previous track
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to skip to previous track: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPlayPause(PlayPause event, Emitter<AudioPlayerState> emit) async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        emit(state.copyWith(status: PlaybackStatus.paused));
      } else {
        await _audioPlayer.play();
        emit(state.copyWith(status: PlaybackStatus.playing));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play/pause: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStop(Stop event, Emitter<AudioPlayerState> emit) async {
    try {
      await _audioPlayer.stop();
      emit(const AudioPlayerState());
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to stop: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSeek(Seek event, Emitter<AudioPlayerState> emit) async {
    try {
      await _audioPlayer.seek(event.position);
      emit(state.copyWith(position: event.position));
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to seek: ${e.toString()}',
      ));
    }
  }

  void _onUpdatePosition(UpdatePosition event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(position: event.position));
  }

  void _onUpdateDuration(UpdateDuration event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(duration: event.duration));
  }

  void _onUpdatePlayerState(UpdatePlayerState event, Emitter<AudioPlayerState> emit) {
    if (event.isPlaying && state.status != PlaybackStatus.playing) {
      emit(state.copyWith(status: PlaybackStatus.playing));
    } else if (!event.isPlaying && state.status == PlaybackStatus.playing) {
      emit(state.copyWith(status: PlaybackStatus.paused));
    }
  }

  void _onPlayerError(PlayerError event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(
      status: PlaybackStatus.error,
      errorMessage: event.message,
    ));
  }

  void _onUpdateCurrentIndex(UpdateCurrentIndex event, Emitter<AudioPlayerState> emit) {
    if (event.index >= 0 && event.index < state.queue.length) {
      emit(state.copyWith(
        currentIndex: event.index,
        currentTrack: state.queue[event.index],
      ));
      print('🎵 Current track index updated to ${event.index}: ${state.queue[event.index].title}');
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
