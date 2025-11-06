import 'package:music_app/features/library/domain/entities/artist.dart';

abstract class LibraryRemoteDataSource {
  /// Scan S3 bucket and return discovered music structure
  Future<List<Artist>> scanBucket(String bucketName, String region);
  
  /// Get direct URL for streaming a track
  String getTrackStreamUrl(String bucketName, String s3Key);
}
