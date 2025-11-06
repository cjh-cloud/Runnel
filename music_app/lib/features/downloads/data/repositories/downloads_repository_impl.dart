import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/entities/album.dart';
import '../../../library/domain/entities/artist.dart';
import '../services/download_service.dart';

class DownloadsRepositoryImpl implements DownloadsRepository {
  final DownloadService downloadService;

  DownloadsRepositoryImpl({required this.downloadService});

  @override
  Future<Either<Failure, DownloadTask>> downloadTrack(
    Track track,
    String bucketUrl,
  ) async {
    try {
      final task = await downloadService.downloadTrack(track, bucketUrl);
      return Right(task);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DownloadTask>>> downloadAlbum(
    Album album,
    String bucketUrl,
  ) async {
    try {
      final tasks = await downloadService.downloadAlbum(album, bucketUrl);
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DownloadTask>>> downloadArtist(
    Artist artist,
    String bucketUrl,
  ) async {
    try {
      final tasks = await downloadService.downloadArtist(artist, bucketUrl);
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DownloadTask>>> getAllDownloads() async {
    try {
      final tasks = await downloadService.getAllTasks();
      return Right(tasks);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getDownloadedTracks() async {
    try {
      final tracks = await downloadService.getDownloadedTracks();
      return Right(tracks);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDownload(String taskId) async {
    try {
      await downloadService.cancelDownload(taskId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DownloadTask>> retryDownload(String taskId) async {
    try {
      final task = await downloadService.retryDownload(taskId);
      if (task == null) {
        return const Left(CacheFailure('Task not found'));
      }
      return Right(task);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDownload(String trackId) async {
    try {
      await downloadService.deleteDownload(trackId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DownloadTask?>> getDownloadTask(String trackId) async {
    try {
      final task = await downloadService.getTaskForTrack(trackId);
      return Right(task);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<bool> isTrackDownloaded(String trackId) async {
    return await downloadService.isTrackDownloaded(trackId);
  }

  @override
  Stream<DownloadTask> watchDownloadProgress(String taskId) {
    return downloadService.watchProgress(taskId);
  }
}
