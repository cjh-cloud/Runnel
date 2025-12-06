import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/features/library/domain/entities/album.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';
import 'package:music_app/features/library/domain/entities/track.dart';

abstract class LibraryRepository {
  /// Scan a bucket and discover all music content
  Future<Either<Failure, List<Artist>>> scanBucket(String bucketName, String region);
  
  /// Load full details (tracks) for a specific artist
  Future<Either<Failure, Artist>> loadArtistDetails(Artist artist);

  /// Get all configured buckets
  Future<Either<Failure, List<BucketConfig>>> getBuckets();
  
  /// Get all saved buckets (alias for getBuckets)
  Future<Either<Failure, List<BucketConfig>>> getSavedBuckets();
  
  /// Add a new bucket configuration
  Future<Either<Failure, void>> addBucket(BucketConfig bucket);
  
  /// Save a bucket configuration (alias for addBucket)
  Future<Either<Failure, void>> saveBucket(BucketConfig bucket);
  
  /// Remove a bucket configuration
  Future<Either<Failure, void>> removeBucket(String bucketName);
  
  /// Delete a bucket configuration (alias for removeBucket)
  Future<Either<Failure, void>> deleteBucket(String bucketName);
  
  /// Get all artists from cache
  Future<Either<Failure, List<Artist>>> getCachedArtists();
  
  /// Get albums for a specific artist
  Future<Either<Failure, List<Album>>> getAlbumsForArtist(String artistName);
  
  /// Get tracks for a specific album
  Future<Either<Failure, List<Track>>> getTracksForAlbum(String artistName, String albumName);
  
  /// Search tracks across all buckets
  Future<Either<Failure, List<Track>>> searchTracks(String query);
  
  /// Refresh catalog for a specific bucket
  Future<Either<Failure, void>> refreshBucket(String bucketName);
}
