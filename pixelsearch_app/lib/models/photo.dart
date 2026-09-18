import 'dart:typed_data';
import 'package:flutter/widgets.dart';

import '../core/placeholder_image.dart';
import '../core/platform_image.dart';

/// Where a photo came from.
enum PhotoSource { sample, device }

/// A single photo in the library. Deliberately free of any platform-specific
/// (photo_manager, dart:io) types so this model compiles on web as well as
/// mobile — file access goes through [fileImage].
class Photo {
  final String id;

  /// The asset's own name as reported by the gallery (or a bundled asset path).
  final String? assetName;

  /// An already-decoded thumbnail held in memory, when a caller has one.
  final Uint8List? thumbBytes;

  /// Path of the thumbnail file the M5 indexer generated, from `photo_rows.thumbPath`.
  /// Thumbnails are files, never blobs — essential at 50k photos.
  final String? thumbPath;

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
  /// Empty for un-indexed photos (web). Read-only for search: the indexer writes
  /// `labelsJson`; [PhotoRepository.rowToPhoto] surfaces it here so M6 hybrid
  /// ranking and the UI can use it. See INDEXING_ARCHITECTURE.md.
  final List<String> labels;

  /// Number of faces detected by ML Kit face detection (M5 indexing); 0 if none
  /// or un-indexed. Drives the M6 "people/portrait" query-intent boost.
  final int faceCount;

  const Photo({
    required this.id,
    this.assetName,
    this.thumbBytes,
    this.thumbPath,
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

  Photo withLabels(List<String> correctedLabels) => Photo(
    id: id,
    assetName: assetName,
    thumbBytes: thumbBytes,
    thumbPath: thumbPath,
    title: title,
    caption: caption,
    tags: tags,
    date: date,
    lat: lat,
    lng: lng,
    place: place,
    album: album,
    source: source,
    labels: correctedLabels,
    faceCount: faceCount,
  );

  /// The image to display: in-memory thumbnail, then the indexed thumbnail file,
  /// then a bundled asset. Falls back to a transparent placeholder so a photo
  /// that has no usable image never throws mid-build.
  ImageProvider get image {
    if (thumbBytes != null) return MemoryImage(thumbBytes!);
    if (source == PhotoSource.device) {
      final preview = deviceThumbnail(id, thumbPath);
      if (preview != null) return preview;
    }
    if (thumbPath != null) {
      final file = fileImage(thumbPath!); // null on web
      if (file != null) return file;
    }
    if (assetName != null && assetName!.startsWith('assets/')) {
      return AssetImage(assetName!);
    }
    return placeholderImage;
  }

  /// A name to show. Indexed photos carry no authored title, so fall back to the
  /// gallery's own asset name.
  String get displayTitle {
    if (title.isNotEmpty) return title;
    final name = assetName;
    return (name == null || name.isEmpty) ? 'Photo' : name;
  }

  /// Descriptors to show in the UI: authored tags if present, otherwise the real
  /// ML Kit labels written by the indexer.
  List<String> get displayTags => tags.isNotEmpty ? tags : labels;

  /// Lower-cased text used by semantic-hybrid lexical scoring, where ML Kit
  /// labels are intentionally excluded.
  String get metadataSearchBlob =>
      [title, caption, ...tags, place ?? '', album].join(' ').toLowerCase();

  /// Lower-cased text used by keyword-only scoring (title, caption, tags,
  /// ML Kit labels, place, album).
  String get searchBlob => [
    title,
    caption,
    ...tags,
    ...labels,
    place ?? '',
    album,
  ].join(' ').toLowerCase();
}
