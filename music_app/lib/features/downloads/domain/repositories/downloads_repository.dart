import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/download_task.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/entities/album.dart';
import '../../../library/domain/entities/artist.dart';

abstract class DownloadsRepository {
  /// Download a single track
  Future<Either<Failure, DownloadTask>> downloadTrack(Track track, String bucketUrl);

  /// Download an entire album
  Future<Either<Failure, List<DownloadTask>>> downloadAlbum(Album album, String bucketUrl);

  /// Download an entire artist's catalog
  Future<Either<Failure, List<DownloadTask>>> downloadArtist(Artist artist, String bucketUrl);

  /// Get all download tasks
  Future<Either<Failure, List<DownloadTask>>> getAllDownloads();

  /// Get all completed downloads
  Future<Either<Failure, List<Track>>> getDownloadedTracks();

  /// Cancel a download
  Future<Either<Failure, void>> cancelDownload(String taskId);

  /// Retry a failed download
  Future<Either<Failure, DownloadTask>> retryDownload(String taskId);

  /// Delete a downloaded track
  Future<Either<Failure, void>> deleteDownload(String trackId);

  /// Get download task by track ID
  Future<Either<Failure, DownloadTask?>> getDownloadTask(String trackId);

  /// Check if track is downloaded
  Future<bool> isTrackDownloaded(String trackId);

  /// Stream download progress
  Stream<DownloadTask> watchDownloadProgress(String taskId);
}
