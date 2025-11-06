import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:music_app/features/library/domain/entities/track.dart';

part 'album.g.dart';

@HiveType(typeId: 1)
class Album extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String bucketName;

  @HiveField(4)
  final String s3Prefix;

  @HiveField(5)
  final String? artworkUrl;

  @HiveField(6)
  final int trackCount;

  @HiveField(7)
  final int? totalDurationMs;

  @HiveField(8)
  final DateTime? addedDate;

  @HiveField(9)
  final List<Track>? tracks;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.bucketName,
    required this.s3Prefix,
    this.artworkUrl,
    this.trackCount = 0,
    this.totalDurationMs,
    this.addedDate,
    this.tracks,
  });

  // Factory constructor for creating from tracks
  factory Album.fromTracks({
    required String name,
    required String artist,
    required String bucketName,
    required String s3Prefix,
    required List<Track> tracks,
    String? artworkUrl,
  }) {
    int totalMs = 0;
    for (var track in tracks) {
      if (track.durationMs != null) {
        totalMs += track.durationMs!;
      }
    }

    return Album(
      id: '${bucketName}_${artist}_$name'.hashCode.toString(),
      name: name,
      artist: artist,
      bucketName: bucketName,
      s3Prefix: s3Prefix,
      artworkUrl: artworkUrl,
      trackCount: tracks.length,
      totalDurationMs: totalMs > 0 ? totalMs : null,
      addedDate: DateTime.now(),
      tracks: tracks,
    );
  }

  Duration? get totalDuration => totalDurationMs != null
      ? Duration(milliseconds: totalDurationMs!)
      : null;

  Album copyWith({
    String? id,
    String? name,
    String? artist,
    String? bucketName,
    String? s3Prefix,
    String? artworkUrl,
    int? trackCount,
    int? totalDurationMs,
    DateTime? addedDate,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      bucketName: bucketName ?? this.bucketName,
      s3Prefix: s3Prefix ?? this.s3Prefix,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackCount: trackCount ?? this.trackCount,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artist,
        bucketName,
        s3Prefix,
        artworkUrl,
        trackCount,
        totalDurationMs,
        addedDate,
      ];
}
