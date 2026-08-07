import 'dart:typed_data';

/// Generates a thumbnail for an asset and returns where it was stored.
///
/// Thumbnails are stored as files (path returned), NOT as DB blobs — at 50k
/// photos, blobs would bloat the database. Device adapter writes into the app
/// cache dir; the fake returns a synthetic path.
abstract interface class ThumbnailGenerator {
  Future<String> generate(String assetId, Uint8List bytes);
}
