part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibraryEvent extends LibraryEvent {}

class ScanBucketEvent extends LibraryEvent {
  final String bucketName;
  final String region;

  const ScanBucketEvent({
    required this.bucketName,
    required this.region,
  });

  @override
  List<Object?> get props => [bucketName, region];
}

class RefreshLibraryEvent extends LibraryEvent {
  final String bucketName;
  final String region;

  const RefreshLibraryEvent({
    required this.bucketName,
    required this.region,
  });

  @override
  List<Object?> get props => [bucketName, region];
}

class AddBucketEvent extends LibraryEvent {
  final String bucketName;
  final String region;

  const AddBucketEvent({
    required this.bucketName,
    required this.region,
  });

  @override
  List<Object?> get props => [bucketName, region];
}

class SwitchBucketEvent extends LibraryEvent {
  final BucketConfig bucket;

  const SwitchBucketEvent(this.bucket);

  @override
  List<Object?> get props => [bucket];
}

class DeleteBucketEvent extends LibraryEvent {
  final String bucketName;

  const DeleteBucketEvent(this.bucketName);

  @override
  List<Object?> get props => [bucketName];
}

class LoadBucketsEvent extends LibraryEvent {}
