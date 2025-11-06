import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget for displaying album artwork from various sources
class AlbumArtwork extends StatelessWidget {
  final String? artworkUrl;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const AlbumArtwork({
    super.key,
    this.artworkUrl,
    this.size = 50,
    this.borderRadius = 4,
    this.placeholderIcon = Icons.album,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: _buildArtwork(context),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context) {
    if (artworkUrl == null || artworkUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // Check if it's a local file path
    if (artworkUrl!.startsWith('/') || artworkUrl!.startsWith('file://')) {
      final filePath = artworkUrl!.replaceFirst('file://', '');
      final file = File(filePath);
      
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }

    // Otherwise treat as network URL
    return CachedNetworkImage(
      imageUrl: artworkUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: size / 3,
          height: size / 3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        placeholderIcon,
        size: size / 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }
}