/// Base class for all exceptions
class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() => 'AppException: $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException([super.message = 'Network error', super.error]);
}

/// S3-related exceptions
class S3Exception extends AppException {
  S3Exception([super.message = 'S3 error', super.error]);
}

/// Storage-related exceptions
class StorageException extends AppException {
  StorageException([super.message = 'Storage error', super.error]);
}

/// Audio-related exceptions
class AudioException extends AppException {
  AudioException([super.message = 'Audio error', super.error]);
}

/// Parsing exceptions
class ParsingException extends AppException {
  ParsingException([super.message = 'Parsing error', super.error]);
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException([super.message = 'Cache error', super.error]);
}

/// Server exceptions
class ServerException implements Exception {
  final String message;
  const ServerException({required this.message});
  
  @override
  String toString() => message;
}
