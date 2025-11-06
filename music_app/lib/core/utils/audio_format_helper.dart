import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

/// Audio format enumeration
enum AudioFormat {
  mp3,
  m4a,
  flac,
  ogg,
  wav,
  unknown;

  /// Get format from file extension
  static AudioFormat fromExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    
    switch (ext) {
      case '.mp3':
        return AudioFormat.mp3;
      case '.m4a':
        return AudioFormat.m4a;
      case '.flac':
        return AudioFormat.flac;
      case '.ogg':
        return AudioFormat.ogg;
      case '.wav':
        return AudioFormat.wav;
      default:
        return AudioFormat.unknown;
    }
  }

  /// Check if file is a supported audio format
  static bool isSupported(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return AppConstants.supportedAudioExtensions.contains(ext);
  }

  /// Get file extension for format
  String get extension {
    switch (this) {
      case AudioFormat.mp3:
        return '.mp3';
      case AudioFormat.m4a:
        return '.m4a';
      case AudioFormat.flac:
        return '.flac';
      case AudioFormat.ogg:
        return '.ogg';
      case AudioFormat.wav:
        return '.wav';
      case AudioFormat.unknown:
        return '';
    }
  }

  /// Get display name for format
  String get displayName {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.m4a:
        return 'M4A';
      case AudioFormat.flac:
        return 'FLAC';
      case AudioFormat.ogg:
        return 'OGG';
      case AudioFormat.wav:
        return 'WAV';
      case AudioFormat.unknown:
        return 'Unknown';
    }
  }
}

/// Helper class for audio format operations
class AudioFormatHelper {
  /// Check if a file path represents an audio file
  static bool isAudioFile(String filePath) {
    return AudioFormat.isSupported(filePath);
  }

  /// Get audio format from file path
  static AudioFormat getFormatFromPath(String filePath) {
    return AudioFormat.fromExtension(filePath);
  }

  /// Get file extension for an audio format
  static String getExtension(AudioFormat format) {
    return format.extension;
  }

  /// Get MIME type for an audio format
  static String getMimeType(AudioFormat format) {
    switch (format) {
      case AudioFormat.mp3:
        return 'audio/mpeg';
      case AudioFormat.m4a:
        return 'audio/mp4';
      case AudioFormat.flac:
        return 'audio/flac';
      case AudioFormat.ogg:
        return 'audio/ogg';
      case AudioFormat.wav:
        return 'audio/wav';
      case AudioFormat.unknown:
        return 'application/octet-stream';
    }
  }

  /// Check if format is lossless
  static bool isLossless(AudioFormat format) {
    return format == AudioFormat.flac || format == AudioFormat.wav;
  }
}
