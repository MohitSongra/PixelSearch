import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pixelsearch/ai/embedding_math.dart';
import 'package:pixelsearch/ai/image_embedder.dart';

/// M4 numerical parity GATE (image path).
///
/// Runs the COMPLETE production pipeline through a real Flutter ONNX Runtime
/// session — image → Flutter preprocessing → Flutter ORT → embedding → L2 —
/// and compares against the Python (open_clip + fp32 ONNX) reference.
///
/// Acceptance (per the brief):
///   1. identical output dimensions (512)
///   2. cosine similarity > 0.999
///   3. max absolute error within tolerance
///   4. identical retrieval ranking (reference_vectors structure, 6/6)
const String kModel =
    '/home/claude/PixelSearch_ModelKit/out/mobileclip_image.onnx';
const String kRefDir = '/home/claude/PixelSearch_ModelKit/parity';
const double kMaxAbsTolerance = 0.02; // fp32-vs-fp32; residual = interpolation

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IMAGE parity: Flutter ONNX Runtime vs Python reference',
      (tester) async {
    final ref = jsonDecode(
      File('$kRefDir/reference_embeddings.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final names = (ref['image_names'] as List).cast<String>();
    final refImg = ref['image_embeds'] as Map<String, dynamic>;
    final textEmbeds = (ref['text_embeds'] as List)
        .map((r) => Float32List.fromList(
            (r as List).map((e) => (e as num).toDouble()).toList()))
        .toList();

    Float32List refVec(String n) => Float32List.fromList(
        (refImg[n] as List).map((e) => (e as num).toDouble()).toList());

    final embedder = OnnxImageEmbedder(modelPath: kModel);
    await embedder.load();
    expect(embedder.isLoaded, isTrue);

    final flutterEmbeds = <String, Float32List>{};
    for (final n in names) {
      final bytes = File('$kRefDir/images/$n.png').readAsBytesSync();
      final image = img.decodeImage(bytes)!;
      final e = await embedder.embed(image);
      flutterEmbeds[n] = e;

      // (1) dims
      expect(e.length, 512, reason: '$n: output dimension');

      final r = refVec(n);
      final cos = cosineSimilarity(e, r);
      var maxAbs = 0.0;
      for (var i = 0; i < 512; i++) {
        final d = (e[i] - r[i]).abs();
        if (d > maxAbs) maxAbs = d;
      }
      // ignore: avoid_print
      print('PARITY $n  cos=${cos.toStringAsFixed(6)}  maxAbs=${maxAbs.toStringAsFixed(5)}');

      // (2) cosine, (3) max abs error
      expect(cos, greaterThan(0.999), reason: '$n: cosine vs Python reference');
      expect(maxAbs, lessThan(kMaxAbsTolerance), reason: '$n: max abs error');
    }

    // (4) identical retrieval ranking: each text query retrieves its own image.
    for (var q = 0; q < textEmbeds.length; q++) {
      var best = -1;
      var bestScore = -1e30;
      for (var i = 0; i < names.length; i++) {
        final s = cosineSimilarity(textEmbeds[q], flutterEmbeds[names[i]]!);
        if (s > bestScore) {
          bestScore = s;
          best = i;
        }
      }
      expect(best, q,
          reason: 'query "${(ref['queries'] as List)[q]}" should retrieve image "${names[q]}"');
    }

    await embedder.dispose();
  });
}
