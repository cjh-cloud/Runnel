import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/downloads_bloc.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/album_artwork.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../player/presentation/bloc/player_event.dart';
import '../bloc/downloads_event.dart';
import '../../domain/entities/downloads_state.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Music'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<DownloadsBloc, DownloadsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.downloadedTracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No downloaded music',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Download tracks for offline listening',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group tracks by artist, then by album
                final tracksByArtist = <String, Map<String, List<Track>>>{};
                for (final track in state.downloadedTracks) {
                  tracksByArtist.putIfAbsent(track.artist, () => {});
                  tracksByArtist[track.artist]!.putIfAbsent(track.album, () => []).add(track);
                }
                
                // Sort tracks within each album by track number
                tracksByArtist.forEach((artist, albums) {
                  albums.forEach((album, tracks) {
                    tracks.sort((a, b) {
                      final aTrackNum = a.trackNumber ?? 999;
                      final bTrackNum = b.trackNumber ?? 999;
                      return aTrackNum.compareTo(bTrackNum);
                    });
                  });
                });

                return ListView.builder(
                  itemCount: tracksByArtist.length,
                  itemBuilder: (context, index) {
                    final artist = tracksByArtist.keys.elementAt(index);
                    final albums = tracksByArtist[artist]!;
                    
                    // Calculate total tracks for this artist
                    final totalTracks = albums.values.fold<int>(0, (sum, tracks) => sum + tracks.length);

                    return ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          artist.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        artist,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$totalTracks ${totalTracks == 1 ? 'track' : 'tracks'} • ${albums.length} ${albums.length == 1 ? 'album' : 'albums'}'),
                      children: albums.entries.map((albumEntry) {
                        final albumName = albumEntry.key;
                        final tracks = albumEntry.value;
                        
                        // Get artwork from the first track that has it
                        final artworkUrl = tracks.firstWhere(
                          (t) => t.artworkUrl != null,
                          orElse: () => tracks.first,
                        ).artworkUrl;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ExpansionTile(
                            leading: artworkUrl != null
                                ? AlbumArtwork(
                                    artworkUrl: artworkUrl,
                                    size: 48,
                                    borderRadius: 4,
                                  )
                                : const Icon(Icons.album, size: 48),
                            title: Text(
                              albumName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}'),
                            children: tracks.map((track) {
                              final durationText = track.duration != null
                                  ? _formatDuration(track.duration!)
                                  : '';

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  child: Text(
                                    track.trackNumber?.toString() ?? '?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(track.title),
                                subtitle: Text(durationText.isNotEmpty ? durationText : track.format.toString().split('.').last.toUpperCase()),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline),
                                      onPressed: () {
                                        // Find all tracks from the same album and queue them
                                        final albumTracks = tracks;
                                        final trackIndex = albumTracks.indexOf(track);
                                        
                                        // Play the album queue starting from this track
                                        context.read<PlayerBloc>().add(
                                          PlayQueue(albumTracks, startIndex: trackIndex, bucketUrl: ''),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text('Delete Download'),
                                            content: Text(
                                              'Are you sure you want to delete "${track.title}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  context.read<DownloadsBloc>().add(
                                                    DeleteDownload(track.id),
                                                  );
                                                  Navigator.pop(dialogContext);
                                                },
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
