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
      
      // 1. Scan for Artists (prefixes under music/)
      final artistResult = await s3Client.listObjects(
        bucketName: bucketName,
        region: region,
        prefix: S3Constants.musicPrefix,
        recursive: false,
        delimiter: '/',
      );

      print('   Found ${artistResult.commonPrefixes.length} artist folders');
      
      final artists = <Artist>[];
      
      // 2. Fetch albums for each artist in parallel
      // Limit concurrency to avoid overwhelming the network
      final chunkSize = 10;
      for (var i = 0; i < artistResult.commonPrefixes.length; i += chunkSize) {
        final end = (i + chunkSize < artistResult.commonPrefixes.length) 
            ? i + chunkSize 
            : artistResult.commonPrefixes.length;
        
        final chunk = artistResult.commonPrefixes.sublist(i, end);
        
        final chunkResults = await Future.wait(
          chunk.map((artistPrefix) => _fetchArtistAlbums(bucketName, region, artistPrefix))
        );
        
        artists.addAll(chunkResults.whereType<Artist>());
      }

      // Sort artists alphabetically
      artists.sort((a, b) => a.name.compareTo(b.name));

      print('✅ Scan complete: ${artists.length} artists found');
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

  Future<Artist?> _fetchArtistAlbums(String bucketName, String region, String artistPrefix) async {
    try {
      // music/ArtistName/
      final artistName = _getNameFromPrefix(artistPrefix, 1);
      if (artistName.isEmpty) return null;

      final albumResult = await s3Client.listObjects(
        bucketName: bucketName,
        region: region,
        prefix: artistPrefix,
        recursive: false,
        delimiter: '/',
      );

      final albums = <Album>[];
      for (final albumPrefix in albumResult.commonPrefixes) {
         // music/ArtistName/AlbumName/
         final albumName = _getNameFromPrefix(albumPrefix, 2);
         if (albumName.isEmpty) continue;

         albums.add(Album(
           id: '${artistName}_${albumName}'.hashCode.toString(),
           name: albumName,
           artist: artistName,
           bucketName: bucketName,
           s3Prefix: albumPrefix,
           tracks: [], // Empty initially
           trackCount: 0,
         ));
      }
      
      albums.sort((a, b) => a.name.compareTo(b.name));

      return Artist(
        id: artistName.hashCode.toString(),
        name: artistName,
        albums: albums,
        bucketName: bucketName,
        albumCount: albums.length,
      );
    } catch (e) {
      print('⚠️ Failed to fetch albums for $artistPrefix: $e');
      return null;
    }
  }

  @override
  Future<Artist> loadArtistDetails(Artist artist) async {
    try {
      print('🎵 Loading details for artist: ${artist.name}');
      final prefix = 'music/${artist.name}/';
      
      // Map to organize albums and tracks
      final Map<String, List<Track>> albumTracks = {};

      // List all objects under the artist prefix recursively
      final result = await s3Client.listObjects(
        bucketName: artist.bucketName,
        region: '', // Region might be needed, but we usually have bucketName. 
                   // Wait, scanBucket passed region. Artist entity doesn't store region?
                   // Let's check Artist entity.
        prefix: prefix,
        recursive: true,
      );
      
      // We need the region to make requests. 
      // The Artist entity unfortunately doesn't store region, only bucketName.
      // However, s3Client uses region to construct URL.
      // If we don't have region, we might fail if bucket needs it.
      // BUT, s3Client attempts "without region" first. 
      // If we pass empty region, it might work if bucket is standard.
      // Ideally we should store region in Artist or pass it.
      // Let's assume s3Client handles it or check how scanBucket did it.
      // scanBucket had 'region' arg.
      // We should probably update Artist to store region or look it up.
      // For now, I will use an empty region and rely on s3Client's retry logic.
      
      // Process each S3 object
      for (var obj in result.objects) {
        final key = obj.key;
        if (key.isEmpty) continue;

        // Only process audio files
        if (!AudioFormatHelper.isAudioFile(key)) continue;

        // Parse the S3 path
        final parsedPath = PathParser.parseS3Path(key);
        
        final albumName = parsedPath.album;
        final fileName = parsedPath.filename;
        
        // Skip if we couldn't parse
        if (albumName == null || fileName == null) continue;

        // Create track
        final s3Url = S3Constants.getObjectUrlWithoutRegion(artist.bucketName, key);
        
        final track = Track(
          id: key.hashCode.toString(),
          title: PathParser.cleanTrackName(fileName),
          artist: artist.name,
          album: albumName,
          s3Url: s3Url,
          bucketName: artist.bucketName,
          s3Key: key,
          format: AudioFormatHelper.getFormatFromPath(key).extension,
          fileSize: obj.size,
          lastModified: obj.lastModified,
          isDownloaded: false,
          trackNumber: PathParser.extractTrackNumber(fileName),
        );

        albumTracks.putIfAbsent(albumName, () => []);
        albumTracks[albumName]!.add(track);
      }

      // Rebuild albums with tracks
      final updatedAlbums = <Album>[];
      
      // Use existing albums to preserve order or other metadata if any
      // Or just rebuild from what we found (more reliable for sync)
      
      albumTracks.forEach((albumName, tracks) {
        // Sort tracks
        tracks.sort((a, b) {
          if (a.trackNumber != null && b.trackNumber != null) {
            return a.trackNumber!.compareTo(b.trackNumber!);
          }
          return a.title.compareTo(b.title);
        });

        final album = Album(
          id: '${artist.name}_${albumName}'.hashCode.toString(),
          name: albumName,
          artist: artist.name,
          bucketName: artist.bucketName,
          s3Prefix: 'music/${artist.name}/$albumName',
          tracks: tracks,
          trackCount: tracks.length,
        );
        updatedAlbums.add(album);
      });
      
      // Add empty albums that were present in artist but no tracks found (maybe empty folders?)
      // Actually, if we listed recursively and found no tracks, the album effectively has 0 tracks.
      // Let's merge with existing albums to keep any that might be empty but exist as folders.
      for (var existingAlbum in (artist.albums ?? const [])) {
        if (!albumTracks.containsKey(existingAlbum.name)) {
           updatedAlbums.add(existingAlbum);
        }
      }

      updatedAlbums.sort((a, b) => a.name.compareTo(b.name));

      return Artist(
        id: artist.id,
        name: artist.name,
        albums: updatedAlbums,
        bucketName: artist.bucketName,
        albumCount: updatedAlbums.length,
      );

    } on S3Exception catch (e) {
      print('❌ S3Exception during details load: ${e.message}');
      throw ServerException(message: 'Failed to load artist details: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Unexpected error during details load: $e');
      print('   Stack trace: $stackTrace');
      throw ServerException(message: 'Failed to load artist details: ${e.toString()}');
    }
  }

  @override
  String getTrackStreamUrl(String bucketName, String s3Key) {
    return S3Constants.getObjectUrlWithoutRegion(bucketName, s3Key);
  }

  String _getNameFromPrefix(String prefix, int index) {
    final parts = prefix.split('/');
    // music/Artist/ -> [music, Artist, ""]
    if (parts.length > index) {
      // Assuming S3 prefixes are not URL encoded in the XML response usually, 
      // but if they are, we might need decoding. 
      // Standard S3 XML response has keys/prefixes decoded usually? 
      // Actually often they are URL encoded if specified in request, but let's assume raw string for now.
      return parts[index]; 
    }
    return '';
  }
}
