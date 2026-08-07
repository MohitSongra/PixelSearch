import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../core/ai_contract.dart';
import 'ai_logger.dart';
import 'image_preprocess.dart';
import 'onnx_encoder.dart';

/// Turns an image into a 512-d L2-normalized MobileCLIP embedding.
/// An interface so tests can fake it and callers depend on the abstraction.
abstract interface class ImageEmbedder {
  Future<void> load();
  bool get isLoaded;
  Future<Float32List> embed(img.Image image);
  Future<void> dispose();
}

/// Production image embedder over ONNX Runtime. Session lifecycle is inherited
/// from [OnnxEncoder]; this class only builds the preprocessed input tensor.
class OnnxImageEmbedder extends OnnxEncoder implements ImageEmbedder {
  OnnxImageEmbedder({
    required super.modelPath,
    super.log = const AiLog('ImageEmbedder'),
  });

  @override
  String get label => 'image';

  @override
  Future<Float32List> embed(img.Image image) async {
    final pre = preprocessForClip(image);
    final input = OrtValueTensor.createTensorWithDataList(pre.data, pre.shape);
    return runEmbedding(input, AiContract.imageInputName);
  }
}
