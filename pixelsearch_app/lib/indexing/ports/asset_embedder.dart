import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Embeds a decoded image into a 512-d L2-normalized vector.
///
/// The indexer depends on this narrow port, not on the AI layer directly, so it
/// stays decoupled from ONNX. The production adapter bridges to
/// `OnnxImageEmbedder` (AI core, unmodified); the fake returns a deterministic vector.
///
/// Takes an **already-decoded** image so a photo is decoded exactly once per
/// indexing pass — see [ThumbnailGenerator]. The pixels handed to CLIP are
/// unchanged; only the number of times they are produced is.
abstract interface class AssetEmbedder {
  Future<Float32List> embed(img.Image image);
}
