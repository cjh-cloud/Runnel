import 'package:equatable/equatable.dart';
import '../entities/download_task.dart';
import '../../../library/domain/entities/track.dart';

class DownloadsState extends Equatable {
  final List<DownloadTask> activeTasks;
  final List<Track> downloadedTracks;
  final bool isLoading;
  final String? errorMessage;

  const DownloadsState({
    this.activeTasks = const [],
    this.downloadedTracks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DownloadsState copyWith({
    List<DownloadTask>? activeTasks,
    List<Track>? downloadedTracks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DownloadsState(
      activeTasks: activeTasks ?? this.activeTasks,
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool isTrackDownloaded(String trackId) {
    return downloadedTracks.any((t) => t.id == trackId);
  }

  bool isTrackDownloading(String trackId) {
    return activeTasks.any((t) => 
      t.track.id == trackId && 
      (t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued)
    );
  }

  DownloadTask? getTaskForTrack(String trackId) {
    try {
      return activeTasks.firstWhere((t) => t.track.id == trackId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        activeTasks,
        downloadedTracks,
        isLoading,
        errorMessage,
      ];
}
