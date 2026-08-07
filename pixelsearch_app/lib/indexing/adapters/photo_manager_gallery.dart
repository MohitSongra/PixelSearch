import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../model/asset_ref.dart';
import '../ports/gallery_source.dart';

/// [GallerySource] backed by MediaStore via `photo_manager`. **Device-only** —
/// verified on device (cannot execute in the Linux/CI sandbox). The scan is
/// paginated so a 50k-photo library streams instead of loading all at once.
class PhotoManagerGallerySource implements GallerySource {
  const PhotoManagerGallerySource({this.pageSize = 500});
  final int pageSize;

  @override
  Future<List<AssetRef>> listAssets() async {
    final paths =
        await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
    if (paths.isEmpty) return const [];
    final album = paths.first;
    final total = await album.assetCountAsync;
    final out = <AssetRef>[];
    for (var page = 0; page * pageSize < total; page++) {
      final entities = await album.getAssetListPaged(page: page, size: pageSize);
      for (final e in entities) {
        out.add(AssetRef(
          id: e.id,
          // MediaStore doesn't expose byte size cheaply; modified-time is the
          // primary change signal on device.
          mtimeMs: e.modifiedDateTime.millisecondsSinceEpoch,
          byteSize: 0,
          width: e.width,
          height: e.height,
          dateTakenMs: e.createDateTime.millisecondsSinceEpoch,
          lat: e.latitude,
          lng: e.longitude,
          album: album.name,
          assetName: e.title,
        ));
      }
    }
    return out;
  }

  @override
  Future<Uint8List?> loadBytes(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.originBytes;
  }
}
