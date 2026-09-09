import 'dart:typed_data';
import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../model/asset_ref.dart';
import '../model/folder_selection.dart';
import '../ports/gallery_source.dart';

/// [GallerySource] backed by MediaStore via `photo_manager`. **Device-only** —
/// verified on device (cannot execute in the Linux/CI sandbox). The adapter
/// pages MediaStore entities, avoiding one huge native entity fetch, then
/// returns the metadata list required by reconciliation. That list is still
/// O(number of assets) memory; pixel bytes remain lazy and one-asset-at-a-time.
class PhotoManagerGallerySource implements GallerySource {
  static const permissionRequest = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );
  const PhotoManagerGallerySource({
    required this.selection,
    this.pageSize = 500,
  }) : assert(pageSize > 0);
  final FolderSelection selection;
  final int pageSize;

  @override
  Future<GallerySnapshot> listAssets() async {
    if (selection.isEmpty) {
      return const GallerySnapshot([], canDeleteMissing: false);
    }
    final permission = await PhotoManager.getPermissionState(
      requestOption: permissionRequest,
    );
    if (!permission.hasAccess) throw StateError('Photo access is unavailable.');
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: selection.allFolders,
      hasAll: selection.allFolders,
      type: RequestType.image,
    );
    if (!selection.allFolders) {
      final available = paths.map((p) => p.id).toSet();
      if (!available.containsAll(selection.folderIds)) {
        throw StateError(
          'A selected folder is unavailable. Choose folders again.',
        );
      }
    }
    final out = <String, AssetRef>{};
    for (final album in paths) {
      if (!selection.allFolders && !selection.folderIds.contains(album.id)) {
        continue;
      }
      await for (final e in _entities(album)) {
        out.putIfAbsent(
          e.id,
          () => AssetRef(
            id: e.id,
            mtimeMs: e.modifiedDateTime.millisecondsSinceEpoch,
            byteSize: 0,
            width: e.width,
            height: e.height,
            dateTakenMs: e.createDateTime.millisecondsSinceEpoch,
            lat: e.latitude,
            lng: e.longitude,
            album: album.name,
            assetName: e.title,
          ),
        );
      }
    }

    // Only metadata IDs are read outside the selection, never photo bytes.
    // This preserves existing search results while still removing actual deletions.
    Set<String>? existingIds;
    if (!selection.allFolders && permission.isAuth) {
      existingIds = {...out.keys};
      final all = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      if (all.isEmpty) {
        throw StateError('Gallery changed during scanning. Retry indexing.');
      }
      for (final album in all) {
        await for (final e in _entities(album)) {
          existingIds.add(e.id);
        }
      }
    }
    final after = await PhotoManager.getPermissionState(
      requestOption: permissionRequest,
    );
    if (!after.hasAccess) {
      throw StateError('Photo access changed during scanning.');
    }
    return GallerySnapshot(
      out.values.toList(),
      existingAssetIds: existingIds,
      canDeleteMissing: permission.isAuth && after.isAuth,
    );
  }

  Stream<AssetEntity> _entities(AssetPathEntity album) async* {
    final total = await album.assetCountAsync;
    for (var page = 0; page * pageSize < total; page++) {
      final entities = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (entities.isEmpty) {
        throw StateError('Gallery changed during scanning. Retry indexing.');
      }
      for (final e in entities) {
        yield e;
      }
    }
  }

  static Future<FolderCatalog> listFolders() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: permissionRequest,
    );
    if (!permission.hasAccess) {
      throw StateError(
        'Photo access denied. Allow photo access in Android settings.',
      );
    }
    final paths = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: RequestType.image,
    );
    final folders = <GalleryFolder>[];
    final nameCounts = <String, int>{};
    for (final path in paths) {
      nameCounts.update(path.name, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final path in paths) {
      folders.add(
        GalleryFolder(
          id: path.id,
          name: path.name,
          count: await path.assetCountAsync,
          relativePath: Platform.isAndroid && nameCounts[path.name]! > 1
              ? await path.relativePathAsync
              : null,
        ),
      );
    }
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return FolderCatalog(folders, limited: !permission.isAuth);
  }

  @override
  Future<Uint8List?> loadBytes(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.originBytes;
  }
}
