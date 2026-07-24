import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Where a photo came from.
enum PhotoSource { sample, device }

/// A single photo in the library. Deliberately free of any platform-specific
/// (photo_manager) types so this model compiles on web as well as mobile.
class Photo {
  final String id;

  /// For bundled sample photos, e.g. 'assets/samples/beach_sunset.jpg'.
  final String? assetName;

  /// For real device photos: a decoded thumbnail (loaded on mobile only).
  final Uint8List? thumbBytes;

  final String title;
  final String caption;
  final List<String> tags;
  final DateTime date;
  final double? lat;
  final double? lng;
  final String? place;
  final String album;
  final PhotoSource source;

  const Photo({
    required this.id,
    this.assetName,
    this.thumbBytes,
    required this.title,
    required this.caption,
    required this.tags,
    required this.date,
    this.lat,
    this.lng,
    this.place,
    required this.album,
    required this.source,
  });

  bool get hasLocation => lat != null && lng != null;

  /// The image to display for this photo (memory thumbnail or bundled asset).
  ImageProvider get image {
    if (thumbBytes != null) return MemoryImage(thumbBytes!);
    if (assetName != null) return AssetImage(assetName!);
    // Fallback: transparent 1x1 so the UI never crashes.
    return const AssetImage('assets/samples/beach_sunset.jpg');
  }

  /// Lower-cased text used by the (mock) semantic search.
  String get searchBlob =>
      [title, caption, ...tags, place ?? '', album].join(' ').toLowerCase();
}
