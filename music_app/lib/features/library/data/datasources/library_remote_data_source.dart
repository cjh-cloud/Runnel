import 'package:music_app/features/library/domain/entities/artist.dart';

abstract class LibraryRemoteDataSource {
  /// Scan S3 bucket for artists and albums (metadata only, no tracks)
  Future<List<Artist>> scanBucket(String bucketName, String region);
  
  /// Load tracks for a specific artist
  Future<Artist> loadArtistDetails(Artist artist);
  
  /// Get direct URL for streaming a track
  String getTrackStreamUrl(String bucketName, String s3Key);
}
