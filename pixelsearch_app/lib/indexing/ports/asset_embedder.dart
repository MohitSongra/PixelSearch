import 'dart:typed_data';

/// Embeds raw image bytes into a 512-d L2-normalized vector.
///
/// The indexer depends on this narrow port, not on the AI layer directly, so it
/// stays decoupled from `image`/ONNX. The production adapter bridges to
/// `OnnxImageEmbedder` (AI core, unmodified); the fake returns a deterministic vector.
abstract interface class AssetEmbedder {
  Future<Float32List> embed(Uint8List imageBytes);
}
