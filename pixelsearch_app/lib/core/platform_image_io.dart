import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'placeholder_image.dart';

/// Native: the indexer stores thumbnails as files and keeps only the path in the
/// DB (never blobs — essential at 50k photos), so displaying one is a plain
/// [FileImage].
///
/// Existence is deliberately **not** checked here: this runs inside `build` for
/// every visible tile, and a `statSync` per tile per frame would be sync I/O on
/// the UI thread. A file that has since been evicted resolves to a decode error
/// that Flutter reports through the widget's error path instead.
ImageProvider? fileImage(String path) => FileImage(File(path));

ImageProvider deviceThumbnail(String id, String? path) =>
    DeviceThumbnailImage(id, path);

Future<Uint8List?> _galleryThumbnail(String id) async {
  final asset = await AssetEntity.fromId(id);
  return asset?.thumbnailDataWithSize(
    const ThumbnailSize(512, 512),
    quality: 85,
  );
}

/// Cache paths are hints, not durable files. Recovery is display-only and never
/// changes the index. Flutter's bounded image cache shares concurrent requests.
class DeviceThumbnailImage extends ImageProvider<DeviceThumbnailImage> {
  const DeviceThumbnailImage(
    this.assetId,
    this.cachePath, {
    this.galleryThumbnail = _galleryThumbnail,
  });
  final String assetId;
  final String? cachePath;
  final Future<Uint8List?> Function(String) galleryThumbnail;

  @override
  Future<DeviceThumbnailImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    DeviceThumbnailImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    Future<ui.Codec> decodeBytes(Uint8List bytes) async =>
        decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    if (cachePath != null) {
      try {
        return await decodeBytes(await File(cachePath!).readAsBytes());
      } catch (_) {
        // Eviction or a corrupt cached image must not hide the original asset.
      }
    }
    try {
      final bytes = await galleryThumbnail(assetId);
      if (bytes != null && bytes.isNotEmpty) return await decodeBytes(bytes);
    } catch (_) {
      // A deleted asset or revoked gallery permission has no available preview.
    }
    return decodeBytes(kTransparentPixelPng);
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceThumbnailImage &&
      other.assetId == assetId &&
      other.cachePath == cachePath &&
      other.galleryThumbnail == galleryThumbnail;

  @override
  int get hashCode => Object.hash(assetId, cachePath, galleryThumbnail);
}
