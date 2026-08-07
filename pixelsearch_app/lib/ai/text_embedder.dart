import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../core/ai_contract.dart';
import 'ai_logger.dart';
import 'clip_tokenizer.dart';
import 'onnx_encoder.dart';

/// Turns a query string into a 512-d L2-normalized MobileCLIP text embedding.
abstract interface class TextEmbedder {
  Future<void> load();
  bool get isLoaded;
  Future<Float32List> embed(String text);
  Future<void> dispose();
}

/// Production text embedder over ONNX Runtime. The [ClipTokenizer] is injected
/// (built once from the bundled vocab), and the ORT session lifecycle is
/// inherited from [OnnxEncoder]; this class only tokenizes and builds the tensor.
class OnnxTextEmbedder extends OnnxEncoder implements TextEmbedder {
  OnnxTextEmbedder({
    required super.modelPath,
    required this.tokenizer,
    super.log = const AiLog('TextEmbedder'),
  });

  final ClipTokenizer tokenizer;

  @override
  String get label => 'text';

  @override
  Future<Float32List> embed(String text) async {
    final ids = tokenizer.tokenize(text); // Int64List(contextLength)
    final input = OrtValueTensor.createTensorWithDataList(
        ids, [1, AiContract.contextLength]);
    return runEmbedding(input, AiContract.textInputName);
  }
}
