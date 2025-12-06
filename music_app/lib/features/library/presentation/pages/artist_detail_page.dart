import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../library/domain/entities/artist.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../player/presentation/bloc/player_event.dart';
import '../../../downloads/presentation/bloc/downloads_bloc.dart';
import '../../../downloads/presentation/bloc/downloads_event.dart';
import '../../../downloads/domain/entities/downloads_state.dart';
import '../widgets/album_artwork.dart';
import '../../../player/presentation/widgets/mini_player.dart';

class ArtistDetailPage extends StatefulWidget {
  final Artist artist;

  const ArtistDetailPage({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  @override
  void initState() {
    super.initState();
    // Trigger lazy load of tracks
    context.read<LibraryBloc>().add(LoadArtistDetailsEvent(widget.artist));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        // Find the latest version of the artist from the bloc state
        Artist artist = widget.artist;
        bool isLoading = false;

        if (state is LibraryLoaded) {
          try {
            artist = state.artists.firstWhere((a) => a.id == widget.artist.id);
          } catch (_) {
            // Artist not found in list (maybe filter active or list changed), stick with passed artist
          }
        }
        
        // Check if we are potentially loading (simple heuristic: albums exist but total tracks is 0)
        // This isn't perfect but works for the initial load case
        if (artist.albumCount > 0 && artist.trackCount == 0 && state is! LibraryError) {
           isLoading = true;
        }

        final albums = artist.albums ?? [];
        // Get the S3 bucket URL
        final bucketUrl = 'https://${artist.bucketName}.s3.amazonaws.com';

        return Scaffold(
          appBar: AppBar(
            title: Text(artist.name),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                Expanded(
                  child: albums.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.album, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No albums found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                    itemCount: albums.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Header
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${albums.length} ${albums.length == 1 ? 'album' : 'albums'}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Download entire artist button
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<DownloadsBloc>().add(
                                  DownloadArtist(artist, bucketUrl),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Downloading all tracks by ${artist.name}'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Download All'),
                            ),
                            const Divider(height: 32),
                          ],
                        ),
                      );
                    }

                    final album = albums[index - 1];
                    final tracks = album.tracks ?? [];
                    final trackCount = tracks.length;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(Icons.album, size: 40),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  album.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Play album button
                              if (tracks.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.play_circle_outline),
                                  tooltip: 'Play album',
                                  onPressed: () {
                                    context.read<PlayerBloc>().add(
                                      PlayQueue(tracks, bucketUrl: bucketUrl),
                                    );
                                  },
                                ),
                              // Download album button
                              IconButton(
                                icon: const Icon(Icons.download_outlined),
                                tooltip: 'Download album',
                                onPressed: () {
                                  context.read<DownloadsBloc>().add(
                                    DownloadAlbum(album, bucketUrl),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Downloading album: ${album.name}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: isLoading && trackCount == 0 
                              ? const LinearProgressIndicator() 
                              : Text(
                                  '$trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
                                ),
                          children: tracks.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : const Text(
                                          'No tracks found',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                ),
                              ]
                            : tracks.map((track) {
                                final duration = track.duration;
                                final durationText = duration != null
                                    ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                                    : '';

                                return ListTile(
                                  leading: track.artworkUrl != null
                                      ? AlbumArtwork(
                                          artworkUrl: track.artworkUrl,
                                          size: 40,
                                          borderRadius: 4,
                                        )
                                      : CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          child: Text(
                                            track.trackNumber?.toString() ?? '?',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  title: Text(track.title),
                                  subtitle: Text(
                                    '${track.format.toString().split('.').last.toUpperCase()}'
                                    '${durationText.isNotEmpty ? ' • $durationText' : ''}',
                                  ),
                                  trailing: BlocBuilder<DownloadsBloc, DownloadsState>(
                                    builder: (context, downloadState) {
                                      final isDownloaded = downloadState.isTrackDownloaded(track.id);
                                      final isDownloading = downloadState.isTrackDownloading(track.id);
                                      final task = downloadState.getTaskForTrack(track.id);

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isDownloading && task != null)
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                value: task.progress,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else if (isDownloaded)
                                            Icon(
                                              Icons.download_done,
                                              color: Theme.of(context).colorScheme.primary,
                                            )
                                          else
                                            IconButton(
                                              icon: const Icon(Icons.download_outlined),
                                              onPressed: () {
                                                context.read<DownloadsBloc>().add(
                                                  DownloadTrack(track, bucketUrl),
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Downloading: ${track.title}'),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.play_circle_outline),
                                            onPressed: () {
                                              // Find the index of this track in the album
                                              final trackIndex = tracks.indexOf(track);
                                              
                                              // Play the entire album queue starting from this track
                                              context.read<PlayerBloc>().add(
                                                PlayQueue(tracks, startIndex: trackIndex, bucketUrl: bucketUrl),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    // Show track details
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(track.title),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildDetailRow('Artist', artist.name),
                                              _buildDetailRow('Album', album.name),
                                              _buildDetailRow('Track #', track.trackNumber?.toString() ?? '-'),
                                              _buildDetailRow('Format', track.format.toString().split('.').last.toUpperCase()),
                                              _buildDetailRow('Duration', durationText.isNotEmpty ? durationText : '-'),
                                              _buildDetailRow('Bucket', track.bucketName),
                                              const Divider(),
                                              const Text(
                                                'S3 Path:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                track.s3Key,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const MiniPlayer(),
            ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
