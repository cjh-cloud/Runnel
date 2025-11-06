import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/download_task.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/entities/album.dart';
import '../../../library/domain/entities/artist.dart';
import '../../../../core/services/artwork_service.dart';

class DownloadService {
  final Dio _dio;
  final ArtworkService _artworkService;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadTask>> _progressControllers = {};
  late Box<DownloadTask> _tasksBox;
  late Box<Track> _downloadedTracksBox;

  DownloadService(this._dio, this._artworkService);

  Future<void> initialize() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(DownloadTaskAdapter());
    }

    _tasksBox = await Hive.openBox<DownloadTask>('download_tasks');
    _downloadedTracksBox = await Hive.openBox<Track>('downloaded_tracks');
  }

  Future<DownloadTask> downloadTrack(Track track, String bucketUrl) async {
    final taskId = '${track.id}_${DateTime.now().millisecondsSinceEpoch}';
    final url = '$bucketUrl/${track.s3Key}';

    // Create download task
    final task = DownloadTask(
      id: taskId,
      track: track,
      status: DownloadStatus.queued,
      createdAt: DateTime.now(),
    );

    // Save task
    await _tasksBox.put(taskId, task);

    // Start download in background
    _startDownload(task, url);

    return task;
  }

  Future<List<DownloadTask>> downloadAlbum(Album album, String bucketUrl) async {
    final tracks = album.tracks ?? [];
    final tasks = <DownloadTask>[];

    for (final track in tracks) {
      final task = await downloadTrack(track, bucketUrl);
      tasks.add(task);
    }

    return tasks;
  }

  Future<List<DownloadTask>> downloadArtist(Artist artist, String bucketUrl) async {
    final albums = artist.albums ?? [];
    final tasks = <DownloadTask>[];

    for (final album in albums) {
      final albumTasks = await downloadAlbum(album, bucketUrl);
      tasks.addAll(albumTasks);
    }

    return tasks;
  }

  Future<void> _startDownload(DownloadTask task, String url) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    final progressController = StreamController<DownloadTask>.broadcast();
    _progressControllers[task.id] = progressController;

    try {
      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // Create file path
      final fileName = url.split('/').last;
      final filePath = '${musicDir.path}/$fileName';

      // Update status to downloading
      var updatedTask = task.copyWith(status: DownloadStatus.downloading);
      await _tasksBox.put(task.id, updatedTask);
      progressController.add(updatedTask);

      // Download file
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            updatedTask = updatedTask.copyWith(progress: progress);
            _tasksBox.put(task.id, updatedTask);
            progressController.add(updatedTask);
          }
        },
      );

      // Download completed
      updatedTask = updatedTask.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: filePath,
        completedAt: DateTime.now(),
      );
      await _tasksBox.put(task.id, updatedTask);
      progressController.add(updatedTask);

      // Extract artwork from the downloaded file
      String? artworkPath;
      try {
        artworkPath = await _artworkService.extractAndSaveArtwork(filePath, task.track.id);
      } catch (e) {
        // Silently fail if artwork extraction doesn't work
      }

      // Update track with local path, artwork, and downloaded status
      final updatedTrack = task.track.copyWith(
        isDownloaded: true,
        localPath: filePath,
        artworkUrl: artworkPath ?? task.track.artworkUrl, // Use extracted artwork or keep existing
      );

      // Add to downloaded tracks
      await _downloadedTracksBox.put(updatedTrack.id, updatedTrack);

      // Clean up
      _cancelTokens.remove(task.id);
      await progressController.close();
      _progressControllers.remove(task.id);
    } catch (e) {
      // Download failed
      final updatedTask = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      await _tasksBox.put(task.id, updatedTask);
      progressController.add(updatedTask);

      _cancelTokens.remove(task.id);
      await progressController.close();
      _progressControllers.remove(task.id);
    }
  }

  Future<List<DownloadTask>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  Future<List<Track>> getDownloadedTracks() async {
    return _downloadedTracksBox.values.toList();
  }

  Future<void> cancelDownload(String taskId) async {
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);

    final task = _tasksBox.get(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(status: DownloadStatus.cancelled);
      await _tasksBox.put(taskId, updatedTask);
      _progressControllers[taskId]?.add(updatedTask);
      await _progressControllers[taskId]?.close();
      _progressControllers.remove(taskId);
    }
  }

  Future<DownloadTask?> retryDownload(String taskId) async {
    final task = _tasksBox.get(taskId);
    if (task == null) return null;

    final url = 'https://${task.track.bucketName}.s3.amazonaws.com/${task.track.s3Key}';
    _startDownload(task, url);

    return task;
  }

  Future<void> deleteDownload(String trackId) async {
    // Find tasks for this track
    final tasks = _tasksBox.values.where((t) => t.track.id == trackId).toList();

    for (final task in tasks) {
      // Delete file if exists
      if (task.localPath != null) {
        final file = File(task.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove task
      await _tasksBox.delete(task.id);
    }

    // Remove from downloaded tracks
    await _downloadedTracksBox.delete(trackId);
  }

  Future<DownloadTask?> getTaskForTrack(String trackId) async {
    try {
      return _tasksBox.values.firstWhere((t) => t.track.id == trackId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isTrackDownloaded(String trackId) async {
    return _downloadedTracksBox.containsKey(trackId);
  }

  Stream<DownloadTask> watchProgress(String taskId) {
    if (!_progressControllers.containsKey(taskId)) {
      _progressControllers[taskId] = StreamController<DownloadTask>.broadcast();
    }
    return _progressControllers[taskId]!.stream;
  }
}

// Hive adapter for DownloadTask
class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final int typeId = 100;

  @override
  DownloadTask read(BinaryReader reader) {
    return DownloadTask(
      id: reader.read() as String,
      track: reader.read() as Track,
      status: DownloadStatus.values[reader.read() as int],
      progress: reader.read() as double,
      localPath: reader.read() as String?,
      errorMessage: reader.read() as String?,
      createdAt: reader.read() as DateTime,
      completedAt: reader.read() as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer.write(obj.id);
    writer.write(obj.track);
    writer.write(obj.status.index);
    writer.write(obj.progress);
    writer.write(obj.localPath);
    writer.write(obj.errorMessage);
    writer.write(obj.createdAt);
    writer.write(obj.completedAt);
  }
}
