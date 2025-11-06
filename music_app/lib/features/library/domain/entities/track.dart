import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../../core/utils/audio_format_helper.dart';

part 'track.g.dart';

@HiveType(typeId: 0)
class Track extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String s3Url;

  @HiveField(5)
  final String bucketName;

  @HiveField(6)
  final String s3Key;

  @HiveField(7)
  final String format;

  @HiveField(8)
  final String? artworkUrl;

  @HiveField(9)
  final int? durationMs;

  @HiveField(10)
  final int? fileSize;

  @HiveField(11)
  final DateTime? lastModified;

  @HiveField(12)
  final bool isDownloaded;

  @HiveField(13)
  final String? localPath;

  @HiveField(14)
  final int? trackNumber;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.s3Url,
    required this.bucketName,
    required this.s3Key,
    required this.format,
    this.artworkUrl,
    this.durationMs,
    this.fileSize,
    this.lastModified,
    this.isDownloaded = false,
    this.localPath,
    this.trackNumber,
  });

  Duration? get duration =>
      durationMs != null ? Duration(milliseconds: durationMs!) : null;

  AudioFormat get audioFormat => AudioFormat.fromExtension(s3Key);

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? s3Url,
    String? bucketName,
    String? s3Key,
    String? format,
    String? artworkUrl,
    int? durationMs,
    int? fileSize,
    DateTime? lastModified,
    bool? isDownloaded,
    String? localPath,
    int? trackNumber,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      s3Url: s3Url ?? this.s3Url,
      bucketName: bucketName ?? this.bucketName,
      s3Key: s3Key ?? this.s3Key,
      format: format ?? this.format,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationMs: durationMs ?? this.durationMs,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      trackNumber: trackNumber ?? this.trackNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        s3Url,
        bucketName,
        s3Key,
        format,
        artworkUrl,
        durationMs,
        fileSize,
        lastModified,
        isDownloaded,
        localPath,
        trackNumber,
      ];
}
