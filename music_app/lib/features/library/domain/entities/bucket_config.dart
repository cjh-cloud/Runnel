import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'bucket_config.g.dart';

@HiveType(typeId: 3)
class BucketConfig extends Equatable {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String region;

  @HiveField(2)
  final bool isDefault;

  @HiveField(3)
  final DateTime addedDate;

  @HiveField(4)
  final int trackCount;

  @HiveField(5)
  final DateTime? lastScanned;

  const BucketConfig({
    required this.name,
    required this.region,
    this.isDefault = false,
    required this.addedDate,
    this.trackCount = 0,
    this.lastScanned,
  });

  BucketConfig copyWith({
    String? name,
    String? region,
    bool? isDefault,
    DateTime? addedDate,
    int? trackCount,
    DateTime? lastScanned,
  }) {
    return BucketConfig(
      name: name ?? this.name,
      region: region ?? this.region,
      isDefault: isDefault ?? this.isDefault,
      addedDate: addedDate ?? this.addedDate,
      trackCount: trackCount ?? this.trackCount,
      lastScanned: lastScanned ?? this.lastScanned,
    );
  }

  @override
  List<Object?> get props => [
        name,
        region,
        isDefault,
        addedDate,
        trackCount,
        lastScanned,
      ];
}
