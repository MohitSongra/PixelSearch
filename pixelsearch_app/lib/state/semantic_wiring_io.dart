import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ai/clip_tokenizer.dart';
import '../ai/text_embedder.dart';
import '../data/search/semantic_search_backend.dart';
import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';

/// Native: assemble the CLIP semantic backend. The fp16 text encoder is expected
/// at `<app support>/models/mobileclip_text_fp16.onnx` (provisioned at runtime,
/// shared with the M5 indexer); the tokenizer is built from the bundled vocab.
///
/// Construction never loads the ONNX session (that's lazy on first query), so a
/// missing model file surfaces later as a graceful keyword degrade rather than a
/// throw here. If provisioning of the *tokenizer/support dir* itself fails, we
/// return null and the caller uses keyword search.
Future<SearchBackend?> buildSemanticBackend(VectorIndex index) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final modelPath = p.join(dir.path, 'models', 'mobileclip_text_fp16.onnx');
    final tokenizer = await ClipTokenizer.fromAsset();
    final embedder = OnnxTextEmbedder(modelPath: modelPath, tokenizer: tokenizer);
    return SemanticSearchBackend(embedder: embedder, index: index);
  } catch (_) {
    return null; // provisioning not ready → keyword fallback
  }
}
