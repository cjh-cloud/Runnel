// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtistAdapter extends TypeAdapter<Artist> {
  @override
  final int typeId = 2;

  @override
  Artist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Artist(
      id: fields[0] as String,
      name: fields[1] as String,
      bucketName: fields[2] as String,
      albumCount: fields[3] as int,
      trackCount: fields[4] as int,
      artworkUrl: fields[5] as String?,
      albums: (fields[6] as List?)?.cast<Album>(),
    );
  }

  @override
  void write(BinaryWriter writer, Artist obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bucketName)
      ..writeByte(3)
      ..write(obj.albumCount)
      ..writeByte(4)
      ..write(obj.trackCount)
      ..writeByte(5)
      ..write(obj.artworkUrl)
      ..writeByte(6)
      ..write(obj.albums);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
