import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';

class ScanBucket {
  final LibraryRepository repository;

  ScanBucket(this.repository);

  Future<Either<Failure, List<Artist>>> call(ScanBucketParams params) async {
    return await repository.scanBucket(params.bucketName, params.region);
  }
}

class ScanBucketParams extends Equatable {
  final String bucketName;
  final String region;

  const ScanBucketParams({
    required this.bucketName,
    required this.region,
  });

  @override
  List<Object> get props => [bucketName, region];
}
