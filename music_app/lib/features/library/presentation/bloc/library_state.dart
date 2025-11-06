part of 'library_bloc.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryScanning extends LibraryState {}

class LibraryRefreshing extends LibraryState {
  final List<Artist> artists;
  final List<BucketConfig> buckets;
  final BucketConfig? currentBucket;

  const LibraryRefreshing({
    required this.artists,
    this.buckets = const [],
    this.currentBucket,
  });

  @override
  List<Object?> get props => [artists, buckets, currentBucket];
}

class LibraryLoaded extends LibraryState {
  final List<Artist> artists;
  final List<BucketConfig> buckets;
  final BucketConfig? currentBucket;

  const LibraryLoaded({
    required this.artists,
    this.buckets = const [],
    this.currentBucket,
  });

  @override
  List<Object?> get props => [artists, buckets, currentBucket];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError({required this.message});

  @override
  List<Object?> get props => [message];
}
