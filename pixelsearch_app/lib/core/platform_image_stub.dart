import 'package:flutter/widgets.dart';

/// Web: no file system and no local index, so there is never a thumbnail file to
/// read. The caller uses the transparent placeholder.
ImageProvider? fileImage(String path) => null;

ImageProvider? deviceThumbnail(String id, String? path) => null;
