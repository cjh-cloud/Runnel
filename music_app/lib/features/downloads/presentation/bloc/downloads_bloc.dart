import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/downloads_state.dart';
import '../../domain/repositories/downloads_repository.dart';
import 'downloads_event.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  final DownloadsRepository repository;
  final Map<String, StreamSubscription> _progressSubscriptions = {};

  DownloadsBloc({required this.repository}) : super(const DownloadsState()) {
    on<LoadDownloads>(_onLoadDownloads);
    on<DownloadTrack>(_onDownloadTrack);
    on<DownloadAlbum>(_onDownloadAlbum);
    on<DownloadArtist>(_onDownloadArtist);
    on<CancelDownload>(_onCancelDownload);
    on<RetryDownload>(_onRetryDownload);
    on<DeleteDownload>(_onDeleteDownload);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
  }

  Future<void> _onLoadDownloads(
    LoadDownloads event,
    Emitter<DownloadsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final tasksResult = await repository.getAllDownloads();
    final downloadedResult = await repository.getDownloadedTracks();

    tasksResult.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (tasks) {
        downloadedResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          )),
          (downloaded) => emit(state.copyWith(
            activeTasks: tasks,
            downloadedTracks: downloaded,
            isLoading: false,
          )),
        );
      },
    );
  }

  Future<void> _onDownloadTrack(
    DownloadTrack event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await repository.downloadTrack(event.track, event.bucketUrl);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (task) {
        final updatedTasks = [...state.activeTasks, task];
        emit(state.copyWith(activeTasks: updatedTasks));

        // Subscribe to progress updates
        _subscribeToProgress(task.id);
      },
    );
  }

  Future<void> _onDownloadAlbum(
    DownloadAlbum event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await repository.downloadAlbum(event.album, event.bucketUrl);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (tasks) {
        final updatedTasks = [...state.activeTasks, ...tasks];
        emit(state.copyWith(activeTasks: updatedTasks));

        // Subscribe to progress updates for all tasks
        for (final task in tasks) {
          _subscribeToProgress(task.id);
        }
      },
    );
  }

  Future<void> _onDownloadArtist(
    DownloadArtist event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await repository.downloadArtist(event.artist, event.bucketUrl);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (tasks) {
        final updatedTasks = [...state.activeTasks, ...tasks];
        emit(state.copyWith(activeTasks: updatedTasks));

        // Subscribe to progress updates for all tasks
        for (final task in tasks) {
          _subscribeToProgress(task.id);
        }
      },
    );
  }

  Future<void> _onCancelDownload(
    CancelDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await repository.cancelDownload(event.taskId);
    _progressSubscriptions[event.taskId]?.cancel();
    _progressSubscriptions.remove(event.taskId);

    // Reload downloads
    add(const LoadDownloads());
  }

  Future<void> _onRetryDownload(
    RetryDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await repository.retryDownload(event.taskId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (task) {
        _subscribeToProgress(task.id);
        add(const LoadDownloads());
      },
    );
  }

  Future<void> _onDeleteDownload(
    DeleteDownload event,
    Emitter<DownloadsState> emit,
  ) async {
    await repository.deleteDownload(event.trackId);
    add(const LoadDownloads());
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<DownloadsState> emit,
  ) {
    final updatedTasks = state.activeTasks.map((task) {
      return task.id == event.task.id ? event.task : task;
    }).toList();

    // If download completed, reload to update downloaded tracks
    if (event.task.isDownloaded) {
      add(const LoadDownloads());
    } else {
      emit(state.copyWith(activeTasks: updatedTasks));
    }
  }

  void _subscribeToProgress(String taskId) {
    _progressSubscriptions[taskId]?.cancel();
    _progressSubscriptions[taskId] = repository
        .watchDownloadProgress(taskId)
        .listen((task) {
      add(UpdateDownloadProgress(task));
    });
  }

  @override
  Future<void> close() {
    for (final subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    return super.close();
  }
}
