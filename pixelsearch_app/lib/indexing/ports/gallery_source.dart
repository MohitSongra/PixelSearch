import 'dart:typed_data';

import '../model/asset_ref.dart';

/// Enumerates the device gallery and loads asset bytes.
///
/// Port (hexagonal architecture). Device adapter: `photo_manager` (MediaStore);
/// tests use an in-memory fake. Enumeration returns only cheap metadata so a
/// 50k-photo scan stays light; bytes are loaded lazily, per asset, during indexing.
abstract interface class GallerySource {
  Future<GallerySnapshot> listAssets();
  Future<Uint8List?> loadBytes(String assetId);
}

/// Candidates are scoped to the user's folders. Existence is gallery-wide so
/// deselection never masquerades as deletion. Limited access is non-authoritative.
class GallerySnapshot {
  const GallerySnapshot(
    this.assets, {
    this.existingAssetIds,
    this.canDeleteMissing = true,
  });
  final List<AssetRef> assets;
  final Set<String>? existingAssetIds;
  final bool canDeleteMissing;
}
