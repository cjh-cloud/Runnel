import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';

class AddBucket {
  final LibraryRepository repository;

  AddBucket(this.repository);

  Future<Either<Failure, void>> call(BucketConfig bucket) async {
    return await repository.addBucket(bucket);
  }
}
