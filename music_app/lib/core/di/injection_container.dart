import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

import '../network/network_info.dart';
import '../network/s3_client.dart';
import '../services/artwork_service.dart';
import '../../features/library/data/datasources/library_local_data_source.dart';
import '../../features/library/data/datasources/library_local_data_source_impl.dart';
import '../../features/library/data/datasources/library_remote_data_source.dart';
import '../../features/library/data/datasources/library_remote_data_source_impl.dart';
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/usecases/scan_bucket.dart';
import '../../features/library/domain/usecases/load_artist_details.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/library/domain/entities/track.dart';
import '../../features/library/domain/entities/album.dart';
import '../../features/library/domain/entities/artist.dart';
import '../../features/library/domain/entities/bucket_config.dart';
import '../../features/player/presentation/bloc/player_bloc.dart';
import '../../features/downloads/presentation/bloc/downloads_bloc.dart';
import '../../features/downloads/data/services/download_service.dart';
import '../../features/downloads/data/repositories/downloads_repository_impl.dart';
import '../../features/downloads/domain/repositories/downloads_repository.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  await initializeDependencies();
}

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TrackAdapter());
  Hive.registerAdapter(AlbumAdapter());
  Hive.registerAdapter(ArtistAdapter());
  Hive.registerAdapter(BucketConfigAdapter());

  // Open Hive boxes
  await Hive.openBox<Artist>('artists');
  await Hive.openBox<BucketConfig>('buckets');

  // Core
  sl.registerLazySingleton(() => S3Client());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ArtworkService());

  // Features
  _registerLibraryFeature();
  _registerAudioPlayerFeature();
  await _registerDownloadsFeature();
}

void _registerLibraryFeature() {
  // Bloc
  sl.registerFactory(
    () => LibraryBloc(
      scanBucket: sl(),
      loadArtistDetails: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => ScanBucket(sl()));
  sl.registerLazySingleton(() => LoadArtistDetails(sl()));

  // Repository
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(s3Client: sl()),
  );

  sl.registerLazySingleton<LibraryLocalDataSource>(
    () => LibraryLocalDataSourceImpl(
      artistBox: Hive.box<Artist>('artists'),
      bucketBox: Hive.box<BucketConfig>('buckets'),
    ),
  );
}

void _registerAudioPlayerFeature() {
  // Bloc - singleton so the same player is shared across the app
  sl.registerLazySingleton<PlayerBloc>(() => PlayerBloc());
}

Future<void> _registerDownloadsFeature() async {
  // Service
  final downloadService = DownloadService(sl(), sl());
  await downloadService.initialize();
  sl.registerLazySingleton(() => downloadService);

  // Repository
  sl.registerLazySingleton<DownloadsRepository>(
    () => DownloadsRepositoryImpl(downloadService: sl()),
  );

  // Bloc
  sl.registerLazySingleton<DownloadsBloc>(() => DownloadsBloc(repository: sl()));
}
