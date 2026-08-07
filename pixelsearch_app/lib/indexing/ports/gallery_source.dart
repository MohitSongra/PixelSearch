import 'dart:typed_data';

import '../model/asset_ref.dart';

/// Enumerates the device gallery and loads asset bytes.
///
/// Port (hexagonal architecture). Device adapter: `photo_manager` (MediaStore);
/// tests use an in-memory fake. Enumeration returns only cheap metadata so a
/// 50k-photo scan stays light; bytes are loaded lazily, per asset, during indexing.
abstract interface class GallerySource {
  Future<List<AssetRef>> listAssets();
  Future<Uint8List?> loadBytes(String assetId);
}
