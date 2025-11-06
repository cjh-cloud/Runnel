import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';

abstract class LibraryLocalDataSource {
  /// Cache artists data
  Future<void> cacheArtists(List<Artist> artists);
  
  /// Get cached artists
  Future<List<Artist>> getCachedArtists();
  
  /// Save bucket configuration
  Future<void> saveBucket(BucketConfig bucket);
  
  /// Get all saved buckets
  Future<List<BucketConfig>> getBuckets();
  
  /// Delete bucket configuration
  Future<void> deleteBucket(String bucketName);
  
  /// Clear all cached data
  Future<void> clearCache();
}
