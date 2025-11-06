import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:music_app/features/library/domain/entities/artist.dart';
import 'package:music_app/features/library/domain/entities/bucket_config.dart';
import 'package:music_app/features/library/domain/usecases/scan_bucket.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_app/core/errors/failures.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final ScanBucket scanBucket;
  final LibraryRepository repository;

  LibraryBloc({
    required this.scanBucket,
    required this.repository,
  }) : super(LibraryInitial()) {
    on<LoadLibraryEvent>(_onLoadLibrary);
    on<ScanBucketEvent>(_onScanBucket);
    on<RefreshLibraryEvent>(_onRefreshLibrary);
    on<LoadBucketsEvent>(_onLoadBuckets);
    on<AddBucketEvent>(_onAddBucket);
    on<SwitchBucketEvent>(_onSwitchBucket);
    on<DeleteBucketEvent>(_onDeleteBucket);
  }

  Future<void> _onLoadLibrary(
    LoadLibraryEvent event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryLoading());
    
    // Load saved buckets
    final bucketsResult = await repository.getSavedBuckets();
    final buckets = bucketsResult.getOrElse(() => []);
    
    // If no buckets configured, show empty state
    if (buckets.isEmpty) {
      emit(LibraryLoaded(
        artists: [],
        buckets: [],
        currentBucket: null,
      ));
      return;
    }
    
    // Find current/default bucket
    final currentBucket = buckets.firstWhere(
      (b) => b.isDefault,
      orElse: () => buckets.first,
    );
    
    // Try to load cached library first
    final cachedResult = await repository.getCachedArtists();
    
    cachedResult.fold(
      (failure) {
        // No cache, need to scan
        add(ScanBucketEvent(
          bucketName: currentBucket.name,
          region: currentBucket.region,
        ));
      },
      (artists) {
        if (artists.isEmpty) {
          // Empty cache, need to scan
          add(ScanBucketEvent(
            bucketName: currentBucket.name,
            region: currentBucket.region,
          ));
        } else {
          emit(LibraryLoaded(
            artists: artists,
            buckets: buckets,
            currentBucket: currentBucket,
          ));
        }
      },
    );
  }

  Future<void> _onScanBucket(
    ScanBucketEvent event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryScanning());
    
    final result = await scanBucket(ScanBucketParams(
      bucketName: event.bucketName,
      region: event.region,
    ));
    
    // Load buckets
    final bucketsResult = await repository.getSavedBuckets();
    final buckets = bucketsResult.getOrElse(() => []);
    
    result.fold(
      (failure) => emit(LibraryError(message: _mapFailureToMessage(failure))),
      (artists) => emit(LibraryLoaded(
        artists: artists,
        buckets: buckets,
        currentBucket: buckets.firstWhere(
          (b) => b.name == event.bucketName,
          orElse: () => BucketConfig(
            name: event.bucketName,
            region: event.region,
            addedDate: DateTime.now(),
          ),
        ),
      )),
    );
  }

  Future<void> _onRefreshLibrary(
    RefreshLibraryEvent event,
    Emitter<LibraryState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;
    List<BucketConfig> buckets = [];
    BucketConfig? currentBucket;
    
    if (currentState is LibraryLoaded) {
      buckets = currentState.buckets;
      currentBucket = currentState.currentBucket;
      emit(LibraryRefreshing(
        artists: currentState.artists,
        buckets: buckets,
        currentBucket: currentBucket,
      ));
    } else {
      emit(LibraryScanning());
    }
    
    final result = await scanBucket(ScanBucketParams(
      bucketName: event.bucketName,
      region: event.region,
    ));
    
    // Reload buckets
    final bucketsResult = await repository.getSavedBuckets();
    buckets = bucketsResult.getOrElse(() => buckets);
    
    result.fold(
      (failure) => emit(LibraryError(message: _mapFailureToMessage(failure))),
      (artists) => emit(LibraryLoaded(
        artists: artists,
        buckets: buckets,
        currentBucket: currentBucket,
      )),
    );
  }

  Future<void> _onLoadBuckets(
    LoadBucketsEvent event,
    Emitter<LibraryState> emit,
  ) async {
    // Load saved buckets
    final bucketsResult = await repository.getSavedBuckets();
    final buckets = bucketsResult.getOrElse(() => []);
    
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      emit(LibraryLoaded(
        artists: currentState.artists,
        buckets: buckets,
        currentBucket: currentState.currentBucket,
      ));
    }
  }

  Future<void> _onAddBucket(
    AddBucketEvent event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryScanning());
    
    // Scan the bucket
    final result = await scanBucket(ScanBucketParams(
      bucketName: event.bucketName,
      region: event.region,
    ));
    
    await result.fold(
      (failure) async {
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (artists) async {
        // Save bucket configuration
        final bucket = BucketConfig(
          name: event.bucketName,
          region: event.region,
          isDefault: false,
          addedDate: DateTime.now(),
          trackCount: artists.fold<int>(0, (sum, artist) => 
            sum + (artist.albums?.fold<int>(0, (aSum, album) => aSum + (album.tracks?.length ?? 0)) ?? 0)),
          lastScanned: DateTime.now(),
        );
        
        await repository.saveBucket(bucket);
        
        // Load all buckets
        final bucketsResult = await repository.getSavedBuckets();
        final buckets = bucketsResult.getOrElse(() => [bucket]);
        
        emit(LibraryLoaded(
          artists: artists,
          buckets: buckets,
          currentBucket: bucket,
        ));
      },
    );
  }

  Future<void> _onSwitchBucket(
    SwitchBucketEvent event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    List<BucketConfig> buckets = [];
    
    if (currentState is LibraryLoaded) {
      buckets = currentState.buckets;
      emit(LibraryRefreshing(
        artists: currentState.artists,
        buckets: buckets,
        currentBucket: event.bucket,
      ));
    } else {
      emit(LibraryScanning());
    }
    
    // Scan the selected bucket
    final result = await scanBucket(ScanBucketParams(
      bucketName: event.bucket.name,
      region: event.bucket.region,
    ));
    
    result.fold(
      (failure) => emit(LibraryError(message: _mapFailureToMessage(failure))),
      (artists) {
        emit(LibraryLoaded(
          artists: artists,
          buckets: buckets,
          currentBucket: event.bucket,
        ));
      },
    );
  }

  Future<void> _onDeleteBucket(
    DeleteBucketEvent event,
    Emitter<LibraryState> emit,
  ) async {
    await repository.deleteBucket(event.bucketName);
    
    // Reload buckets
    final bucketsResult = await repository.getSavedBuckets();
    final buckets = bucketsResult.getOrElse(() => []);
    
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      final deletedWasCurrent = currentState.currentBucket?.name == event.bucketName;
      
      if (deletedWasCurrent && buckets.isNotEmpty) {
        // Switch to first available bucket
        add(SwitchBucketEvent(buckets.first));
      } else {
        emit(LibraryLoaded(
          artists: currentState.artists,
          buckets: buckets,
          currentBucket: deletedWasCurrent ? null : currentState.currentBucket,
        ));
      }
    }
  }

  String _mapFailureToMessage(Failure failure) {
    String message;
    if (failure is ServerFailure) {
      message = failure.message;
    } else if (failure is CacheFailure) {
      message = failure.message;
    } else if (failure is NetworkFailure) {
      message = failure.message;
    } else {
      message = 'Unexpected error occurred';
    }
    print('🚨 LibraryBloc Error: $message');
    return message;
  }
}
