import 'package:photo_manager/photo_manager.dart';
import '../models/photo.dart';

const _months = [
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
];

/// Real device gallery access (Android / iOS) via photo_manager.
///
/// This is Milestone M1 of the plan: request media permission, enumerate the
/// gallery through MediaStore, read metadata (date, GPS) and decode a
/// thumbnail for each photo. The real CLIP indexing pipeline (M4–M5) would
/// then embed these; for the demo they are searchable by date/album/location.
class DeviceGallery {
  static bool get isSupported => true;

  static Future<List<Photo>> load({int limit = 80}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) {
      return <Photo>[];
    }

    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (albums.isEmpty) return <Photo>[];

    final all = albums.first;
    final total = await all.assetCountAsync;
    if (total == 0) return <Photo>[];

    final end = limit < total ? limit : total;
    final assets = await all.getAssetListRange(start: 0, end: end);

    final photos = <Photo>[];
    for (final asset in assets) {
      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(320, 320),
      );
      if (bytes == null) continue;

      final date = asset.createDateTime;
      double? lat = asset.latitude;
      double? lng = asset.longitude;
      if (lat == null || lng == null || (lat == 0 && lng == 0)) {
        lat = null;
        lng = null;
      }

      photos.add(
        Photo(
          id: 'dev_${asset.id}',
          thumbBytes: bytes,
          title: (asset.title == null || asset.title!.isEmpty)
              ? 'Photo'
              : asset.title!,
          caption: 'From your device gallery.',
          tags: _deriveTags(asset, date, lat != null),
          date: date,
          lat: lat,
          lng: lng,
          place: lat != null ? 'Tagged location' : null,
          album: 'Camera',
          source: PhotoSource.device,
        ),
      );
    }
    return photos;
  }

  static List<String> _deriveTags(
      AssetEntity asset, DateTime date, bool hasGps) {
    final tags = <String>['photo', '${date.year}', _months[date.month - 1]];
    if (hasGps) tags.add('travel');
    if (asset.width >= asset.height) {
      tags.add('landscape');
    } else {
      tags.add('portrait');
    }
    return tags;
  }
}
