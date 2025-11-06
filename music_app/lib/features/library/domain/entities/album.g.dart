// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlbumAdapter extends TypeAdapter<Album> {
  @override
  final int typeId = 1;

  @override
  Album read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Album(
      id: fields[0] as String,
      name: fields[1] as String,
      artist: fields[2] as String,
      bucketName: fields[3] as String,
      s3Prefix: fields[4] as String,
      artworkUrl: fields[5] as String?,
      trackCount: fields[6] as int,
      totalDurationMs: fields[7] as int?,
      addedDate: fields[8] as DateTime?,
      tracks: (fields[9] as List?)?.cast<Track>(),
    );
  }

  @override
  void write(BinaryWriter writer, Album obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.bucketName)
      ..writeByte(4)
      ..write(obj.s3Prefix)
      ..writeByte(5)
      ..write(obj.artworkUrl)
      ..writeByte(6)
      ..write(obj.trackCount)
      ..writeByte(7)
      ..write(obj.totalDurationMs)
      ..writeByte(8)
      ..write(obj.addedDate)
      ..writeByte(9)
      ..write(obj.tracks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
