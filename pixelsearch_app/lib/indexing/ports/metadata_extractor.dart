import 'dart:typed_data';

import '../model/asset_ref.dart';

/// EXIF / metadata for an asset.
class PhotoMetadata {
  const PhotoMetadata({
    this.dateTakenMs,
    this.lat,
    this.lng,
    this.width = 0,
    this.height = 0,
    this.place,
  });
  final int? dateTakenMs;
  final double? lat;
  final double? lng;
  final int width;
  final int height;
  final String? place;

  static const empty = PhotoMetadata();
}

/// Extracts EXIF/metadata. Device adapter reads EXIF from the asset bytes; the
/// [AssetRef] carries what MediaStore already knows as a fallback.
abstract interface class MetadataExtractor {
  Future<PhotoMetadata> extract(AssetRef asset, Uint8List bytes);
}
