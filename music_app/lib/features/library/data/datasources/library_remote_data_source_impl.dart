import 'package:music_app/core/constants/s3_constants.dart';
import 'package:music_app/core/errors/exceptions.dart';
import 'package:music_app/core/network/s3_client.dart';
import 'package:music_app/core/utils/audio_format_helper.dart';
import 'package:music_app/core/utils/path_parser.dart';
import 'package:music_app/features/library/data/datasources/library_remote_data_source.dart';
import 'package:music_app/features/library/domain/entities/album.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/track.dart';

class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final S3Client s3Client;

  LibraryRemoteDataSourceImpl({required this.s3Client});

  @override
  Future<List<Artist>> scanBucket(String bucketName, String region) async {
    try {
      print('🎵 Starting bucket scan: $bucketName ($region)');
      
      // Map to organize artists and albums
      final Map<String, Map<String, List<Track>>> artistAlbumTracks = {};

      // List all objects under the music/ prefix
      final objects = await s3Client.listObjects(
        bucketName: bucketName,
        region: region,
        prefix: S3Constants.musicPrefix,
        recursive: true,
      );

      print('   Processing ${objects.length} objects...');

      // Process each S3 object
      for (var obj in objects) {
        final key = obj.key;
        if (key.isEmpty) continue;

        // Only process audio files
        if (!AudioFormatHelper.isAudioFile(key)) continue;

        // Parse the S3 path
        final parsedPath = PathParser.parseS3Path(key);
        
        final artistName = parsedPath.artist;
        final albumName = parsedPath.album;
        final fileName = parsedPath.filename;
        
        // Skip if we couldn't parse artist/album/filename
        if (artistName == null || albumName == null || fileName == null) continue;

        // Create track
        // Use URL without region for public buckets (more compatible)
        final s3Url = S3Constants.getObjectUrlWithoutRegion(bucketName, key);
        
        final track = Track(
          id: key.hashCode.toString(),
          title: PathParser.cleanTrackName(fileName),
          artist: artistName,
          album: albumName,
          s3Url: s3Url,
          bucketName: bucketName,
          s3Key: key,
          format: AudioFormatHelper.getFormatFromPath(key).extension,
          fileSize: obj.size,
          lastModified: obj.lastModified,
          isDownloaded: false,
          trackNumber: PathParser.extractTrackNumber(fileName),
        );

        // Organize into structure
        artistAlbumTracks.putIfAbsent(artistName, () => {});
        artistAlbumTracks[artistName]!.putIfAbsent(albumName, () => []);
        artistAlbumTracks[artistName]![albumName]!.add(track);
      }

      // Convert map to Artist entities
      final artists = <Artist>[];
      artistAlbumTracks.forEach((artistName, albums) {
        final albumList = <Album>[];
        albums.forEach((albumName, tracks) {
          // Sort tracks by track number
          tracks.sort((a, b) {
            if (a.trackNumber != null && b.trackNumber != null) {
              return a.trackNumber!.compareTo(b.trackNumber!);
            }
            return a.title.compareTo(b.title);
          });

          final album = Album(
            id: '${artistName}_${albumName}'.hashCode.toString(),
            name: albumName,
            artist: artistName,
            bucketName: bucketName,
            s3Prefix: 'music/$artistName/$albumName',
            tracks: tracks,
            trackCount: tracks.length,
          );
          albumList.add(album);
        });

        // Sort albums alphabetically
        albumList.sort((a, b) => a.name.compareTo(b.name));

        final artist = Artist(
          id: artistName.hashCode.toString(),
          name: artistName,
          albums: albumList,
          bucketName: bucketName,
          albumCount: albumList.length,
        );
        artists.add(artist);
      });

      // Sort artists alphabetically
      artists.sort((a, b) => a.name.compareTo(b.name));

      print('✅ Scan complete: ${artists.length} artists, ${artistAlbumTracks.values.fold(0, (sum, albums) => sum + albums.length)} albums');

      return artists;
    } on S3Exception catch (e) {
      print('❌ S3Exception during scan: ${e.message}');
      throw ServerException(message: 'Failed to scan bucket: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Unexpected error during scan: $e');
      print('   Stack trace: $stackTrace');
      throw ServerException(message: 'Failed to scan bucket: ${e.toString()}');
    }
  }

  @override
  String getTrackStreamUrl(String bucketName, String s3Key) {
    // For public buckets, use URL without region for better compatibility
    return S3Constants.getObjectUrlWithoutRegion(bucketName, s3Key);
  }
}
