import 'dart:typed_data';

import 'package:exif/exif.dart';

import '../model/asset_ref.dart';
import '../ports/metadata_extractor.dart';

/// Reads EXIF opportunistically for a precise capture time, falling back to what
/// MediaStore already provided on the [AssetRef] (GPS/date/dimensions). EXIF
/// parsing is pure Dart; wired on device alongside the gallery scanner.
class ExifMetadataExtractor implements MetadataExtractor {
  const ExifMetadataExtractor();

  @override
  Future<PhotoMetadata> extract(AssetRef asset, Uint8List bytes) async {
    var dateMs = asset.dateTakenMs;
    try {
      final tags = await readExifFromBytes(bytes);
      final raw =
          tags['EXIF DateTimeOriginal']?.printable ??
          tags['Image DateTime']?.printable;
      final parsed = _parseExifDate(raw);
      if (parsed != null) dateMs = parsed;
    } catch (_) {
      // best-effort — MediaStore metadata remains the fallback
    }
    return PhotoMetadata(
      dateTakenMs: dateMs,
      lat: asset.lat,
      lng: asset.lng,
      width: asset.width,
      height: asset.height,
    );
  }

  int? _parseExifDate(String? s) {
    if (s == null || s.isEmpty) return null;
    // EXIF format: "YYYY:MM:DD HH:MM:SS"
    final m = RegExp(
      r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(s);
    if (m == null) return null;
    return DateTime(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    ).millisecondsSinceEpoch;
  }
}
