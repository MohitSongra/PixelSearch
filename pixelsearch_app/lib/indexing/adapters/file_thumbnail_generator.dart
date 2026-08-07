import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ports/thumbnail_generator.dart';

/// Downscales to a JPEG thumbnail in the app temp dir and returns its path.
/// Thumbnails are files (paths stored in the DB), never blobs — essential at 50k.
class FileThumbnailGenerator implements ThumbnailGenerator {
  const FileThumbnailGenerator({this.size = 256, this.quality = 80});
  final int size;
  final int quality;

  @override
  Future<String> generate(String assetId, Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('cannot decode image for thumbnail');
    }
    final landscape = decoded.width >= decoded.height;
    final thumb = img.copyResize(
      decoded,
      width: landscape ? size : null,
      height: landscape ? null : size,
    );
    final jpg = img.encodeJpg(thumb, quality: quality);

    final dir = await getTemporaryDirectory();
    final thumbsDir = Directory(p.join(dir.path, 'thumbnails'));
    if (!thumbsDir.existsSync()) thumbsDir.createSync(recursive: true);
    final file = File(p.join(thumbsDir.path, '${_safe(assetId)}.jpg'));
    await file.writeAsBytes(jpg, flush: true);
    return file.path;
  }

  String _safe(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
