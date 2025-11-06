// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bucket_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BucketConfigAdapter extends TypeAdapter<BucketConfig> {
  @override
  final int typeId = 3;

  @override
  BucketConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BucketConfig(
      name: fields[0] as String,
      region: fields[1] as String,
      isDefault: fields[2] as bool,
      addedDate: fields[3] as DateTime,
      trackCount: fields[4] as int,
      lastScanned: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BucketConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.region)
      ..writeByte(2)
      ..write(obj.isDefault)
      ..writeByte(3)
      ..write(obj.addedDate)
      ..writeByte(4)
      ..write(obj.trackCount)
      ..writeByte(5)
      ..write(obj.lastScanned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BucketConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
