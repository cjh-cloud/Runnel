/// Hive box and type ID constants
class HiveConstants {
  // Box names
  static const String artistsBox = 'artists';
  static const String albumsBox = 'albums';
  static const String tracksBox = 'tracks';
  static const String bucketsBox = 'buckets';
  static const String downloadsBox = 'downloads';
  static const String settingsBox = 'settings';

  // Type IDs for Hive adapters
  static const int trackTypeId = 0;
  static const int albumTypeId = 1;
  static const int artistTypeId = 2;
  static const int bucketConfigTypeId = 3;
}
