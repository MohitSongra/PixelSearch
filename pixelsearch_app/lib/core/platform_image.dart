import 'package:flutter/widgets.dart';

// Native reads the cached thumbnail file (pulls in dart:io); web has no file
// system, so it gets the stub that returns null. This conditional import is what
// lets the platform-free `Photo` model resolve an on-disk thumbnail without ever
// importing dart:io — the same boundary pattern as `semantic_wiring.dart`.
import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_io.dart' as impl;

/// An [ImageProvider] for the thumbnail file the M5 indexer wrote at [path], or
/// null when this platform cannot read files (web). Callers fall back to
/// `placeholderImage`.
ImageProvider? fileImage(String path) => impl.fileImage(path);
