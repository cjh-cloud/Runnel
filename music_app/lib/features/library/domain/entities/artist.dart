import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:music_app/features/library/domain/entities/album.dart';

part 'artist.g.dart';

@HiveType(typeId: 2)
class Artist extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bucketName;

  @HiveField(3)
  final int albumCount;

  @HiveField(4)
  final int trackCount;

  @HiveField(5)
  final String? artworkUrl;

  @HiveField(6)
  final List<Album>? albums;

  const Artist({
    required this.id,
    required this.name,
    required this.bucketName,
    this.albumCount = 0,
    this.trackCount = 0,
    this.artworkUrl,
    this.albums,
  });

  // Factory constructor for creating from nested data
  factory Artist.fromAlbums({
    required String name,
    required String bucketName,
    required List<Album> albums,
    String? artworkUrl,
  }) {
    int totalTracks = 0;
    for (var album in albums) {
      totalTracks += album.trackCount;
    }

    return Artist(
      id: '${bucketName}_$name'.hashCode.toString(),
      name: name,
      bucketName: bucketName,
      albumCount: albums.length,
      trackCount: totalTracks,
      artworkUrl: artworkUrl,
      albums: albums,
    );
  }

  Artist copyWith({
    String? id,
    String? name,
    String? bucketName,
    int? albumCount,
    int? trackCount,
    String? artworkUrl,
    List<Album>? albums,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      bucketName: bucketName ?? this.bucketName,
      albumCount: albumCount ?? this.albumCount,
      trackCount: trackCount ?? this.trackCount,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      albums: albums ?? this.albums,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        bucketName,
        albumCount,
        trackCount,
        artworkUrl,
        albums,
      ];
}
