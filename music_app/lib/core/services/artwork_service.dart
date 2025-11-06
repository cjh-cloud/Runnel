import 'dart:io';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for extracting and managing album artwork from audio files
class ArtworkService {
  /// Extract artwork from an audio file's metadata
  /// Returns the artwork bytes if found, null otherwise
  Future<Uint8List?> extractArtworkFromFile(String filePath) async {
    try {
      final tag = await AudioTags.read(filePath);
      
      if (tag != null && tag.pictures.isNotEmpty) {
        return tag.pictures.first.bytes;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save artwork bytes to a file and return the file path
  Future<String?> saveArtwork(Uint8List artworkBytes, String trackId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory('${appDir.path}/artwork');
      
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }
      
      final artworkPath = path.join(artworkDir.path, '$trackId.jpg');
      final artworkFile = File(artworkPath);
      await artworkFile.writeAsBytes(artworkBytes);
      
      return artworkPath;
    } catch (e) {
      print('Error saving artwork: $e');
      return null;
    }
  }

  /// Extract and save artwork from an audio file
  /// Returns the saved artwork file path if successful
  Future<String?> extractAndSaveArtwork(String audioFilePath, String trackId) async {
    final artworkBytes = await extractArtworkFromFile(audioFilePath);
    
    if (artworkBytes != null) {
      return await saveArtwork(artworkBytes, trackId);
    }
    
    return null;
  }

  /// Delete artwork file
  Future<void> deleteArtwork(String artworkPath) async {
    try {
      final file = File(artworkPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting artwork: $e');
    }
  }

  /// Clean up all artwork files
  Future<void> cleanupAllArtwork() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory('${appDir.path}/artwork');
      
      if (await artworkDir.exists()) {
        await artworkDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up artwork: $e');
    }
  }
}
