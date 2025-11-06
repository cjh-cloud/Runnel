// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackAdapter extends TypeAdapter<Track> {
  @override
  final int typeId = 0;

  @override
  Track read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Track(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      s3Url: fields[4] as String,
      bucketName: fields[5] as String,
      s3Key: fields[6] as String,
      format: fields[7] as String,
      artworkUrl: fields[8] as String?,
      durationMs: fields[9] as int?,
      fileSize: fields[10] as int?,
      lastModified: fields[11] as DateTime?,
      isDownloaded: fields[12] as bool,
      localPath: fields[13] as String?,
      trackNumber: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Track obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.s3Url)
      ..writeByte(5)
      ..write(obj.bucketName)
      ..writeByte(6)
      ..write(obj.s3Key)
      ..writeByte(7)
      ..write(obj.format)
      ..writeByte(8)
      ..write(obj.artworkUrl)
      ..writeByte(9)
      ..write(obj.durationMs)
      ..writeByte(10)
      ..write(obj.fileSize)
      ..writeByte(11)
      ..write(obj.lastModified)
      ..writeByte(12)
      ..write(obj.isDownloaded)
      ..writeByte(13)
      ..write(obj.localPath)
      ..writeByte(14)
      ..write(obj.trackNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
