import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/exceptions.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/core/network/network_info.dart';
import 'package:music_app/features/library/data/datasources/library_local_data_source.dart';
import 'package:music_app/features/library/data/datasources/library_remote_data_source.dart';
import 'package:music_app/features/library/domain/entities/album.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';
import 'package:music_app/features/library/domain/entities/track.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remoteDataSource;
  final LibraryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LibraryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Artist>>> scanBucket(
    String bucketName,
    String region,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final artists = await remoteDataSource.scanBucket(
        bucketName,
        region,
      );

      // Cache the results
      await localDataSource.cacheArtists(artists);

      return Right(artists);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Artist>>> getCachedArtists() async {
    try {
      final artists = await localDataSource.getCachedArtists();
      return Right(artists);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get cached data: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addBucket(BucketConfig bucket) async {
    try {
      await localDataSource.saveBucket(bucket);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to save bucket: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeBucket(String bucketName) async {
    try {
      await localDataSource.deleteBucket(bucketName);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete bucket: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsForArtist(String artistName) async {
    try {
      final artists = await localDataSource.getCachedArtists();
      final artist = artists.firstWhere(
        (a) => a.name == artistName,
        orElse: () => throw CacheException('Artist not found'),
      );
      return Right(artist.albums ?? []);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get albums: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksForAlbum(
    String artistName,
    String albumName,
  ) async {
    try {
      final artists = await localDataSource.getCachedArtists();
      final artist = artists.firstWhere(
        (a) => a.name == artistName,
        orElse: () => throw CacheException('Artist not found'),
      );
      final album = (artist.albums ?? []).firstWhere(
        (a) => a.name == albumName,
        orElse: () => throw CacheException('Album not found'),
      );
      return Right(album.tracks ?? []);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get tracks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> searchTracks(String query) async {
    try {
      final artists = await localDataSource.getCachedArtists();
      final List<Track> matchingTracks = [];
      
      for (final artist in artists) {
        for (final album in (artist.albums ?? [])) {
          if (album.tracks != null) {
            matchingTracks.addAll(
              album.tracks!.where((track) =>
                  track.title.toLowerCase().contains(query.toLowerCase()) ||
                  track.artist.toLowerCase().contains(query.toLowerCase()) ||
                  track.album.toLowerCase().contains(query.toLowerCase())),
            );
          }
        }
      }
      
      return Right(matchingTracks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to search tracks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshBucket(String bucketName) async {
    try {
      // Get bucket configuration to find region
      final buckets = await localDataSource.getBuckets();
      final bucket = buckets.firstWhere(
        (b) => b.name == bucketName,
        orElse: () => throw CacheException('Bucket not found'),
      );
      
      // Rescan the bucket
      return await scanBucket(bucket.name, bucket.region);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to refresh bucket: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BucketConfig>>> getBuckets() async {
    try {
      final buckets = await localDataSource.getBuckets();
      return Right(buckets);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get buckets: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BucketConfig>>> getSavedBuckets() async {
    return await getBuckets();
  }

  @override
  Future<Either<Failure, void>> saveBucket(BucketConfig bucket) async {
    return await addBucket(bucket);
  }

  @override
  Future<Either<Failure, void>> deleteBucket(String bucketName) async {
    return await removeBucket(bucketName);
  }

  Future<Either<Failure, void>> clearCache() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to clear cache: ${e.toString()}'));
    }
  }
}
