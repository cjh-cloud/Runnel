import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';

class GetCachedArtists {
  final LibraryRepository repository;

  GetCachedArtists(this.repository);

  Future<Either<Failure, List<Artist>>> call() async {
    return await repository.getCachedArtists();
  }
}
