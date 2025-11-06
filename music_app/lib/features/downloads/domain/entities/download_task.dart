import 'package:equatable/equatable.dart';
import '../../../library/domain/entities/track.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}

class DownloadTask extends Equatable {
  final String id;
  final Track track;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? localPath;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.track,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.localPath,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  DownloadTask copyWith({
    String? id,
    Track? track,
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      track: track ?? this.track,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      errorMessage: errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isDownloaded => status == DownloadStatus.completed && localPath != null;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;

  @override
  List<Object?> get props => [
        id,
        track,
        status,
        progress,
        localPath,
        errorMessage,
        createdAt,
        completedAt,
      ];
}
