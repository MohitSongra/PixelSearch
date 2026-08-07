import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../ai/image_embedder.dart';
import '../ports/asset_embedder.dart';

/// Bridges the indexer's [AssetEmbedder] port to the AI core's [ImageEmbedder]
/// (used unmodified). Decodes bytes → image → 512-d embedding. Native-only
/// (ONNX Runtime). This is the seam that keeps the indexer decoupled from the
/// image/ONNX stack while reusing the exact, parity-verified embedder.
class OnnxAssetEmbedder implements AssetEmbedder {
  OnnxAssetEmbedder(this._embedder);
  final ImageEmbedder _embedder;

  @override
  Future<Float32List> embed(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw const FormatException('could not decode image bytes');
    }
    return _embedder.embed(image);
  }
}
