import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pixelsearch/ai/clip_tokenizer.dart';
import 'package:pixelsearch/ai/embedding_math.dart';
import 'package:pixelsearch/ai/image_embedder.dart';
import 'package:pixelsearch/ai/text_embedder.dart';

import 'support/modelkit_paths.dart';

/// M4.4 — GOLDEN VALIDATION SUITE (the permanent AI validation framework).
///
/// Runs the COMPLETE image + text pipeline through a real Flutter ONNX Runtime
/// session and validates it end-to-end against the ModelKit reference, then
/// writes a deterministic VALIDATION_REPORT.md.
///
/// Acceptance: 100% retrieval on the reference set, stable ranking, no drift,
/// repeatable across executions.
Float32List _vec(dynamic list) => Float32List.fromList(
  (list as List).map((e) => (e as num).toDouble()).toList(),
);

List<int> _rankOrder(List<double> scores) {
  final idx = List<int>.generate(scores.length, (i) => i);
  idx.sort((a, b) => scores[b].compareTo(scores[a]));
  return idx;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GOLDEN end-to-end AI validation', (tester) async {
    final paths = ModelKitPaths.resolve();
    paths.requireFiles(includeImages: true, includeReferenceVectors: true);
    // --- references ---
    final refEmb =
        jsonDecode(File(paths.referenceEmbeddings).readAsStringSync())
            as Map<String, dynamic>;
    final names = (refEmb['image_names'] as List).cast<String>();
    final queries = (refEmb['queries'] as List).cast<String>();
    final refImg = {
      for (final n in names) n: _vec((refEmb['image_embeds'] as Map)[n]),
    };
    final refTxt = (refEmb['text_embeds'] as List)
        .map(_vec)
        .toList(growable: false);
    final refVec =
        jsonDecode(File(paths.referenceVectors).readAsStringSync())
            as Map<String, dynamic>;
    final refSim = (refVec['sim_matrix'] as List)
        .map((r) => (r as List).map((e) => (e as num).toDouble()).toList())
        .toList();

    // --- embed via real Flutter ORT ---
    final imageEmbedder = OnnxImageEmbedder(modelPath: paths.imageModel);
    await imageEmbedder.load();
    final tokenizer = await ClipTokenizer.fromGzipFile(paths.vocab);
    final textEmbedder = OnnxTextEmbedder(
      modelPath: paths.textModel,
      tokenizer: tokenizer,
    );
    await textEmbedder.load();

    final fImg = <String, Float32List>{};
    for (final n in names) {
      final bytes = File('${paths.imagesDir}/$n.png').readAsBytesSync();
      fImg[n] = await imageEmbedder.embed(img.decodeImage(bytes)!);
    }
    final fTxt = [for (final q in queries) await textEmbedder.embed(q)];

    // --- 1. dimensions + normalization ---
    double worstNormErr = 0;
    for (final e in [...fImg.values, ...fTxt]) {
      expect(e.length, 512, reason: 'embedding dimension');
      var n = 0.0;
      for (final v in e) {
        n += v * v;
      }
      worstNormErr = math.max(worstNormErr, (math.sqrt(n) - 1.0).abs());
    }
    expect(
      worstNormErr,
      lessThan(1e-3),
      reason: 'all embeddings L2-normalized',
    );

    // --- 2. embedding parity vs reference ---
    var minImgCos = 1.0, minTxtCos = 1.0;
    for (final n in names) {
      minImgCos = math.min(minImgCos, cosineSimilarity(fImg[n]!, refImg[n]!));
    }
    for (var i = 0; i < queries.length; i++) {
      minTxtCos = math.min(minTxtCos, cosineSimilarity(fTxt[i], refTxt[i]));
    }
    expect(minImgCos, greaterThan(0.999), reason: 'image embedding parity');
    expect(minTxtCos, greaterThan(0.9999), reason: 'text embedding parity');

    // --- 3. similarity matrix, retrieval accuracy, Top-K ranking ---
    final sim = [
      for (var q = 0; q < queries.length; q++)
        [for (final n in names) cosineSimilarity(fTxt[q], fImg[n]!)],
    ];
    var correct = 0;
    var rankingStable = true;
    for (var q = 0; q < queries.length; q++) {
      final order = _rankOrder(sim[q]);
      if (order.first == q) correct++;
      // Stable ranking: same order as the reference cosine ranking.
      final refOrder = _rankOrder([
        for (final n in names) cosineSimilarity(refTxt[q], refImg[n]!),
      ]);
      if (!_sameOrder(order, refOrder)) rankingStable = false;
      // Cross-check vs reference_vectors.json argmax (its documented purpose).
      expect(_argmax(refSim[q]), q, reason: 'reference_vectors diagonal q=$q');
    }
    expect(correct, queries.length, reason: '100% retrieval accuracy');
    expect(rankingStable, isTrue, reason: 'ranking matches reference order');

    // --- 4. repeatability (deterministic across executions) ---
    final imgAgain = await imageEmbedder.embed(
      img.decodeImage(
        File('${paths.imagesDir}/${names.first}.png').readAsBytesSync(),
      )!,
    );
    final txtAgain = await textEmbedder.embed(queries.first);
    expect(
      _identical(imgAgain, fImg[names.first]!),
      isTrue,
      reason: 'image embedding repeatable',
    );
    expect(
      _identical(txtAgain, fTxt.first),
      isTrue,
      reason: 'text embedding repeatable',
    );

    // --- 5. auto-generated, deterministic report ---
    final report = StringBuffer()
      ..writeln('# PixelSearch AI — Golden Validation Report')
      ..writeln()
      ..writeln(
        'Generated by `integration_test/golden_validation_test.dart` '
        '(real Flutter ONNX Runtime, fp32). Deterministic — no timestamps.',
      )
      ..writeln()
      ..writeln('## Summary')
      ..writeln('| check | result |')
      ..writeln('|---|---|')
      ..writeln(
        '| Retrieval accuracy | $correct/${queries.length} '
        '(${(100 * correct / queries.length).toStringAsFixed(0)}%) |',
      )
      ..writeln(
        '| Min image cosine vs reference | ${minImgCos.toStringAsFixed(6)} |',
      )
      ..writeln(
        '| Min text cosine vs reference | ${minTxtCos.toStringAsFixed(6)} |',
      )
      ..writeln(
        '| All embeddings L2-normalized | yes (max ‖v‖-1 = '
        '${worstNormErr.toStringAsExponential(1)}) |',
      )
      ..writeln(
        '| Ranking stable vs reference | ${rankingStable ? 'yes' : 'NO'} |',
      )
      ..writeln('| Repeatable across executions | yes |')
      ..writeln('| reference_vectors.json diagonal | 6/6 |')
      ..writeln()
      ..writeln('## Per-query retrieval (Top-1 → image)')
      ..writeln('| query | retrieved | expected | ok |')
      ..writeln('|---|---|---|---|');
    for (var q = 0; q < queries.length; q++) {
      final top = names[_argmax(sim[q])];
      report.writeln(
        '| ${queries[q]} | $top | ${names[q]} | '
        '${top == names[q] ? '✓' : '✗'} |',
      );
    }
    File(paths.validationReport).writeAsStringSync(report.toString());

    await imageEmbedder.dispose();
    await textEmbedder.dispose();
  });
}

int _argmax(List<double> xs) {
  var best = 0;
  for (var i = 1; i < xs.length; i++) {
    if (xs[i] > xs[best]) best = i;
  }
  return best;
}

bool _sameOrder(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _identical(Float32List a, Float32List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
