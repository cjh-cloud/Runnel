import 'package:path/path.dart' as path;

/// Utility class for parsing S3 paths and extracting metadata
class PathParser {
  /// Parse S3 key to extract artist and album
  /// Expected format: music/artist_name/album_name/track.mp3
  static ParsedPath parseS3Key(String s3Key) {
    final parts = s3Key.split('/');
    
    // Remove 'music/' prefix if present
    final relevantParts = parts.where((p) => p.isNotEmpty && p != 'music').toList();
    
    String? artist;
    String? album;
    String? filename;
    
    if (relevantParts.length >= 3) {
      artist = relevantParts[0];
      album = relevantParts[1];
      filename = relevantParts.last;
    } else if (relevantParts.length == 2) {
      artist = relevantParts[0];
      filename = relevantParts.last;
    } else if (relevantParts.isNotEmpty) {
      filename = relevantParts.last;
    }
    
    return ParsedPath(
      artist: artist,
      album: album,
      filename: filename,
      fullPath: s3Key,
    );
  }

  /// Alias for parseS3Key for backwards compatibility
  static ParsedPath parseS3Path(String s3Key) => parseS3Key(s3Key);

  /// Alias for cleanTrackTitle for backwards compatibility
  static String cleanTrackName(String filename) => cleanTrackTitle(filename);

  /// Extract track number from filename
  /// Handles patterns like: "01 - Track Name.mp3", "01. Track Name.mp3", "1 Track Name.mp3"
  static int? extractTrackNumber(String filename) {
    // Remove extension
    final nameWithoutExt = path.basenameWithoutExtension(filename);
    
    // Try to match patterns: "01 - ", "01. ", "01 "
    final patterns = [
      RegExp(r'^(\d+)\s*-\s*'),  // "01 - "
      RegExp(r'^(\d+)\.\s*'),     // "01. "
      RegExp(r'^(\d+)\s+'),       // "01 "
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(nameWithoutExt);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    
    return null;
  }

  /// Clean filename to get track title
  /// Removes track numbers and common prefixes
  static String cleanTrackTitle(String filename) {
    var title = path.basenameWithoutExtension(filename);
    
    // Remove track number patterns
    title = title.replaceFirst(RegExp(r'^\d+\s*-\s*'), '');
    title = title.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    title = title.replaceFirst(RegExp(r'^\d+\s+'), '');
    
    return title.trim();
  }

  /// Check if a path is likely an album artwork file
  static bool isArtworkFile(String filename) {
    final name = filename.toLowerCase();
    final artworkNames = [
      'cover.jpg', 'cover.png',
      'folder.jpg', 'folder.png',
      'album.jpg', 'album.png',
      'artwork.jpg', 'artwork.png',
    ];
    
    return artworkNames.contains(path.basename(name));
  }
}

/// Result of parsing an S3 path
class ParsedPath {
  final String? artist;
  final String? album;
  final String? filename;
  final String fullPath;

  ParsedPath({
    this.artist,
    this.album,
    this.filename,
    required this.fullPath,
  });

  @override
  String toString() {
    return 'ParsedPath(artist: $artist, album: $album, filename: $filename)';
  }
}
