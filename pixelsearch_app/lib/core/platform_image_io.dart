import 'dart:io';

import 'package:flutter/widgets.dart';

/// Native: the indexer stores thumbnails as files and keeps only the path in the
/// DB (never blobs — essential at 50k photos), so displaying one is a plain
/// [FileImage].
///
/// Existence is deliberately **not** checked here: this runs inside `build` for
/// every visible tile, and a `statSync` per tile per frame would be sync I/O on
/// the UI thread. A file that has since been evicted resolves to a decode error
/// that Flutter reports through the widget's error path instead.
ImageProvider? fileImage(String path) => FileImage(File(path));
