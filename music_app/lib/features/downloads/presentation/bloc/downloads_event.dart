import 'package:equatable/equatable.dart';
import '../../domain/entities/download_task.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/entities/album.dart';
import '../../../library/domain/entities/artist.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloads extends DownloadsEvent {
  const LoadDownloads();
}

class DownloadTrack extends DownloadsEvent {
  final Track track;
  final String bucketUrl;

  const DownloadTrack(this.track, this.bucketUrl);

  @override
  List<Object?> get props => [track, bucketUrl];
}

class DownloadAlbum extends DownloadsEvent {
  final Album album;
  final String bucketUrl;

  const DownloadAlbum(this.album, this.bucketUrl);

  @override
  List<Object?> get props => [album, bucketUrl];
}

class DownloadArtist extends DownloadsEvent {
  final Artist artist;
  final String bucketUrl;

  const DownloadArtist(this.artist, this.bucketUrl);

  @override
  List<Object?> get props => [artist, bucketUrl];
}

class CancelDownload extends DownloadsEvent {
  final String taskId;

  const CancelDownload(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class RetryDownload extends DownloadsEvent {
  final String taskId;

  const RetryDownload(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class DeleteDownload extends DownloadsEvent {
  final String trackId;

  const DeleteDownload(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

class UpdateDownloadProgress extends DownloadsEvent {
  final DownloadTask task;

  const UpdateDownloadProgress(this.task);

  @override
  List<Object?> get props => [task];
}
