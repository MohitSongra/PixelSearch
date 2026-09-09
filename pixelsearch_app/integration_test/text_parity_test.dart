import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pixelsearch/ai/clip_tokenizer.dart';
import 'package:pixelsearch/ai/embedding_math.dart';
import 'package:pixelsearch/ai/text_embedder.dart';

import 'support/modelkit_paths.dart';

/// M4.3 numerical parity GATE (text path).
///
/// Complete production pipeline through a real Flutter ONNX Runtime session:
/// query → CLIP BPE tokenizer → Flutter ORT (text encoder) → L2 → embedding —
/// compared against the Python (open_clip + fp32 ONNX) reference.
///
/// Acceptance: identical dims (512), cosine ≥ 0.9999.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TEXT parity: Flutter ONNX Runtime vs Python reference', (
    tester,
  ) async {
    final paths = ModelKitPaths.resolve();
    paths.requireFiles();
    final ref =
        jsonDecode(File(paths.referenceEmbeddings).readAsStringSync())
            as Map<String, dynamic>;
    final queries = (ref['queries'] as List).cast<String>();
    final refText = (ref['text_embeds'] as List)
        .map(
          (r) => Float32List.fromList(
            (r as List).map((e) => (e as num).toDouble()).toList(),
          ),
        )
        .toList();

    final tokenizer = await ClipTokenizer.fromGzipFile(paths.vocab);
    final embedder = OnnxTextEmbedder(
      modelPath: paths.textModel,
      tokenizer: tokenizer,
    );
    await embedder.load();
    expect(embedder.isLoaded, isTrue);

    final flutter = <Float32List>[];
    for (var i = 0; i < queries.length; i++) {
      final e = await embedder.embed(queries[i]);
      flutter.add(e);

      expect(e.length, 512, reason: 'dims for "${queries[i]}"');
      final cos = cosineSimilarity(e, refText[i]);
      var maxAbs = 0.0;
      for (var j = 0; j < 512; j++) {
        final d = (e[j] - refText[i][j]).abs();
        if (d > maxAbs) maxAbs = d;
      }
      // ignore: avoid_print
      print(
        'TEXTPARITY "${queries[i]}"  cos=${cos.toStringAsFixed(6)}  maxAbs=${maxAbs.toStringAsFixed(5)}',
      );
      expect(cos, greaterThan(0.9999), reason: 'cosine for "${queries[i]}"');
    }

    // Cross-check: each query embedding is its own nearest neighbour among the 6.
    for (var q = 0; q < queries.length; q++) {
      var best = -1;
      var bestScore = -1e30;
      for (var i = 0; i < queries.length; i++) {
        final s = cosineSimilarity(flutter[q], refText[i]);
        if (s > bestScore) {
          bestScore = s;
          best = i;
        }
      }
      expect(best, q, reason: 'query $q nearest reference');
    }

    await embedder.dispose();
  });
}
