import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/player_state.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import 'album_artwork.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        if (!state.hasTrack) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;
        final progress = state.duration.inMilliseconds > 0
            ? state.position.inMilliseconds / state.duration.inMilliseconds
            : 0.0;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
              ),
              // Player controls
              ListTile(
                leading: AlbumArtwork(
                  artworkUrl: track.artworkUrl,
                  size: 48,
                  borderRadius: 8,
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  state.queue.length > 1
                      ? '${track.artist} • ${_formatDuration(state.position)} / ${_formatDuration(state.duration)} • ${state.currentIndex + 1}/${state.queue.length}'
                      : '${track.artist} • ${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous button
                    if (state.queue.length > 1 && state.currentIndex > 0)
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () {
                          context.read<PlayerBloc>().add(const SkipPrevious());
                        },
                      ),
                    // Play/Pause button
                    if (state.status == PlaybackStatus.loading ||
                        state.status == PlaybackStatus.buffering)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          context.read<PlayerBloc>().add(const PlayPause());
                        },
                      ),
                    // Next button
                    if (state.queue.length > 1 && state.currentIndex < state.queue.length - 1)
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () {
                          context.read<PlayerBloc>().add(const SkipNext());
                        },
                      ),
                    // Stop button
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<PlayerBloc>().add(const Stop());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
