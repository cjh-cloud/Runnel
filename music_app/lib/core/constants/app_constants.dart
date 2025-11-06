/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Music App';
  static const String appVersion = '1.0.0';

  // Default S3 Configuration
  static const String defaultBucketName = 'runnel-sec-aksjhdcy';
  static const String defaultRegion = 'ap-southeast-2';
  static const String musicPrefix = 'music/';

  // Supported Audio Formats
  static const List<String> supportedAudioExtensions = [
    '.mp3',
    '.m4a',
    '.flac',
    '.ogg',
    '.wav',
  ];

  // Album Artwork Filenames
  static const List<String> artworkFilenames = [
    'cover.jpg',
    'cover.png',
    'folder.jpg',
    'folder.png',
    'album.jpg',
    'album.png',
  ];

  // Storage Limits
  static const int maxCacheSizeMB = 5120; // 5GB
  static const int maxDownloadRetries = 3;

  // Network
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Playback
  static const Duration seekStepDuration = Duration(seconds: 10);
  static const int maxRecentlyPlayedTracks = 50;

  // Hive Box Names
  static const String bucketBoxName = 'buckets';
  static const String trackBoxName = 'tracks';
  static const String albumBoxName = 'albums';
  static const String artistBoxName = 'artists';
  static const String downloadBoxName = 'downloads';
  static const String settingsBoxName = 'settings';
  static const String playbackBoxName = 'playback';
}
