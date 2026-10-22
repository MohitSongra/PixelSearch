import '../ai/clip_tokenizer.dart';
import '../ai/text_embedder.dart';
import '../core/model_locator.dart';
import '../data/search/semantic_search_backend.dart';
import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';

/// Native: assemble the CLIP semantic backend over whichever text encoder is
/// provisioned under `<app support>/models/` (fp16 preferred, fp32 accepted for
/// CPU testing — [ModelLocator]); the tokenizer is built from the bundled vocab.
///
/// Returning **null when no text model is present** is deliberate: the caller
/// then uses the keyword backend, and the UI's mode badge reports "Keyword"
/// truthfully. Previously the backend was constructed unconditionally and — because
/// the ONNX session loads lazily and the degrade latch only trips on a *failed
/// query* — the badge claimed "Semantic" on a device with no model installed at
/// all. Construction still never loads the session, so a model that is present
/// but unrunnable (fp16 without an fp16-capable EP, KI-2) degrades on first
/// query exactly as before.
Future<SearchBackend?> buildSemanticBackend(VectorIndex index) async {
  try {
    final model = await const ModelLocator().resolveText();
    if (model == null) return null; // not provisioned → keyword, badge honest
    final tokenizer = await ClipTokenizer.fromAsset();
    final embedder = OnnxTextEmbedder(
      modelPath: model.path,
      tokenizer: tokenizer,
    );
    return SemanticSearchBackend(embedder: embedder, index: index);
  } catch (_) {
    return null; // provisioning not ready → keyword fallback
  }
}
