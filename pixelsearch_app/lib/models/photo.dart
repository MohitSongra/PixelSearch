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

  /// On-device object labels from ML Kit image labeling (M5 indexing).
  /// Empty for un-indexed photos (bundled samples, web). Read-only for search:
  /// the indexer writes `labelsJson`; [PhotoRepository.rowToPhoto] surfaces it
  /// here so M6 hybrid ranking can use it. See INDEXING_ARCHITECTURE.md.
  final List<String> labels;

  /// Number of faces detected by ML Kit face detection (M5 indexing); 0 if none
  /// or un-indexed. Drives the M6 "people/portrait" query-intent boost.
  final int faceCount;

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
    this.labels = const [],
    this.faceCount = 0,
  });

  bool get hasLocation => lat != null && lng != null;

  /// The image to display for this photo (memory thumbnail or bundled asset).
  ImageProvider get image {
    if (thumbBytes != null) return MemoryImage(thumbBytes!);
    if (assetName != null) return AssetImage(assetName!);
    // Fallback: transparent 1x1 so the UI never crashes.
    return const AssetImage('assets/samples/beach_sunset.jpg');
  }

  /// Lower-cased text used by lexical/keyword scoring (title, caption, tags,
  /// ML Kit labels, place, album).
  String get searchBlob =>
      [title, caption, ...tags, ...labels, place ?? '', album]
          .join(' ')
          .toLowerCase();
}
