/// An immutable reference to a gallery asset as reported by a [GallerySource].
///
/// The `(mtimeMs, byteSize)` pair is the change-detection fingerprint: if either
/// differs from what the store recorded, the asset is treated as **changed** and
/// re-indexed. Everything here is cheap metadata — no pixels — so scanning a
/// 50k-photo gallery stays light.
class AssetRef {
  const AssetRef({
    required this.id,
    required this.mtimeMs,
    required this.byteSize,
    this.width = 0,
    this.height = 0,
    this.dateTakenMs,
    this.lat,
    this.lng,
    this.album = '',
    this.assetName,
  });

  final String id;
  final int mtimeMs;
  final int byteSize;
  final int width;
  final int height;
  final int? dateTakenMs;
  final double? lat;
  final double? lng;
  final String album;
  final String? assetName;
}
