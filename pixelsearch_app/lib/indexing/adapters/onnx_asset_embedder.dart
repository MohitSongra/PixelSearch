import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../ai/image_embedder.dart';
import '../ports/asset_embedder.dart';

/// Bridges the indexer's [AssetEmbedder] port to the AI core's [ImageEmbedder]
/// (used unmodified). Native-only (ONNX Runtime). This is the seam that keeps
/// the indexer decoupled from the ONNX stack while reusing the exact,
/// parity-verified embedder.
///
/// Decoding happens once in [AssetProcessor]; this adapter is now a pure
/// pass-through, which is all it ever needed to be.
class OnnxAssetEmbedder implements AssetEmbedder {
  OnnxAssetEmbedder(this._embedder);
  final ImageEmbedder _embedder;

  @override
  Future<Float32List> embed(img.Image image) => _embedder.embed(image);
}
