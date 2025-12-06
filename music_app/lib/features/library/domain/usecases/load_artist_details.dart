import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';

class LoadArtistDetails {
  final LibraryRepository repository;

  LoadArtistDetails(this.repository);

  Future<Either<Failure, Artist>> call(Artist artist) async {
    return await repository.loadArtistDetails(artist);
  }
}

