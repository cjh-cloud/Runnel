import 'package:hive_flutter/hive_flutter.dart';
import 'package:music_app/core/errors/exceptions.dart';
import 'package:music_app/features/library/data/datasources/library_local_data_source.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';

class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  final Box<Artist> artistBox;
  final Box<BucketConfig> bucketBox;

  LibraryLocalDataSourceImpl({
    required this.artistBox,
    required this.bucketBox,
  });

  @override
  Future<void> cacheArtists(List<Artist> artists) async {
    try {
      await artistBox.clear();
      for (var artist in artists) {
        await artistBox.put(artist.name, artist);
      }
    } catch (e) {
      throw CacheException('Failed to cache artists: ${e.toString()}');
    }
  }

  @override
  Future<List<Artist>> getCachedArtists() async {
    try {
      return artistBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get cached artists: ${e.toString()}');
    }
  }

  @override
  Future<void> saveBucket(BucketConfig bucket) async {
    try {
      await bucketBox.put(bucket.name, bucket);
    } catch (e) {
      throw CacheException('Failed to save bucket: ${e.toString()}');
    }
  }

  @override
  Future<List<BucketConfig>> getBuckets() async {
    try {
      return bucketBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get buckets: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBucket(String bucketName) async {
    try {
      await bucketBox.delete(bucketName);
    } catch (e) {
      throw CacheException('Failed to delete bucket: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await artistBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache: ${e.toString()}');
    }
  }
}
