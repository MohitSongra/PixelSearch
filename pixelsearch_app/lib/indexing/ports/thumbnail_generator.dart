import 'package:image/image.dart' as img;

/// Generates a thumbnail for an asset and returns where it was stored.
///
/// Thumbnails are stored as files (path returned), NOT as DB blobs — at 50k
/// photos, blobs would bloat the database. Device adapter writes into the app
/// cache dir; the fake returns a synthetic path.
///
/// Takes an **already-decoded** image: [AssetProcessor] decodes each asset once
/// and hands the same pixels to every stage. Decoding per stage cost a second
/// full JPEG decode per photo (~418 ms measured on device) for no benefit.
abstract interface class ThumbnailGenerator {
  Future<String> generate(String assetId, img.Image image);
}
