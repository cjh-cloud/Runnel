import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// S3-related failures
class S3Failure extends Failure {
  const S3Failure([String message = 'S3 operation failed']) : super(message);
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure([String message = 'Storage operation failed']) : super(message);
}

/// Audio playback failures
class AudioFailure extends Failure {
  const AudioFailure([String message = 'Audio playback failed']) : super(message);
}

/// Parsing/metadata failures
class ParsingFailure extends Failure {
  const ParsingFailure([String message = 'Failed to parse data']) : super(message);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache operation failed']) : super(message);
}

/// Download failures
class DownloadFailure extends Failure {
  const DownloadFailure([String message = 'Download failed']) : super(message);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) : super(message);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied']) : super(message);
}
