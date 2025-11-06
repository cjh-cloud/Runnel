import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/library_bloc.dart';
import '../../../../debug/s3_test_page.dart';
import 'artist_detail_page.dart';
import 'buckets_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'Manage Buckets',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BucketsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryInitial || state is LibraryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading library...'),
                ],
              ),
            );
          }

          if (state is LibraryScanning) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Scanning S3 bucket...'),
                  SizedBox(height: 10),
                  Text(
                    'This may take a moment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (state is LibraryRefreshing) {
            return _buildLibraryView(context, state.artists, isRefreshing: true);
          }

          if (state is LibraryLoaded) {
            if (state.artists.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildLibraryView(context, state.artists);
          }

          if (state is LibraryError) {
            return _buildErrorState(context, state.message);
          }

          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          // Don't show refresh button if no buckets are configured
          if (state is LibraryLoaded && state.currentBucket == null) {
            return const SizedBox.shrink();
          }
          
          final isLoading = state is LibraryScanning || 
                           state is LibraryLoading ||
                           state is LibraryRefreshing;
          
          // Get current bucket from state
          String? bucketName;
          String? region;
          
          if (state is LibraryLoaded && state.currentBucket != null) {
            bucketName = state.currentBucket!.name;
            region = state.currentBucket!.region;
          } else if (state is LibraryRefreshing && state.currentBucket != null) {
            bucketName = state.currentBucket!.name;
            region = state.currentBucket!.region;
          }
          
          // Don't show button if no bucket is available
          if (bucketName == null || region == null) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: isLoading ? null : () {
              context.read<LibraryBloc>().add(
                RefreshLibraryEvent(
                  bucketName: bucketName!,
                  region: region!,
                ),
              );
            },
            tooltip: 'Refresh Library',
            child: isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No S3 Bucket Configured',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add an S3 bucket to start streaming music',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BucketsPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add S3 Bucket'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Library',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                context.read<LibraryBloc>().add(LoadLibraryEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const S3TestPage()),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug S3 Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryView(BuildContext context, List artists, {bool isRefreshing = false}) {
    return RefreshIndicator(
      onRefresh: () async {
        // Get current bucket from state
        final state = context.read<LibraryBloc>().state;
        String? bucketName;
        String? region;
        
        if (state is LibraryLoaded && state.currentBucket != null) {
          bucketName = state.currentBucket!.name;
          region = state.currentBucket!.region;
        } else if (state is LibraryRefreshing && state.currentBucket != null) {
          bucketName = state.currentBucket!.name;
          region = state.currentBucket!.region;
        }
        
        if (bucketName != null && region != null) {
          context.read<LibraryBloc>().add(
            RefreshLibraryEvent(
              bucketName: bucketName,
              region: region,
            ),
          );
          // Wait a bit for the refresh to complete
          await Future.delayed(const Duration(seconds: 1));
        }
      },
      child: ListView.builder(
        itemCount: artists.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRefreshing)
                    const LinearProgressIndicator(),
                  if (isRefreshing)
                    const SizedBox(height: 16),
                  Text(
                    'Artists (${artists.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh • Tap to view albums',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          final artist = artists[index - 1];
          final albumCount = artist.albums?.length ?? 0;
          final trackCount = artist.albums?.fold<int>(
                0,
                (int sum, album) => sum + ((album.tracks?.length ?? 0) as int),
              ) ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  artist.name?.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                artist.name ?? 'Unknown Artist',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$albumCount ${albumCount == 1 ? 'album' : 'albums'} • $trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistDetailPage(artist: artist),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

