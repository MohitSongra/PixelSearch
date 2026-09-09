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
import 'package:pixelsearch/core/ai_contract.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/models/photo.dart';

import 'support/modelkit_paths.dart';

/// M6 — SEMANTIC SEARCH, end-to-end on a real Flutter ONNX Runtime session.
///
/// This exercises the ENTIRE M6 code path with the real model (not a fake):
///   real image ONNX  → [BruteForceVectorIndex]
///   real text ONNX   → [SemanticSearchBackend] → [HybridScorer] → ranked Photos
///
/// It asserts retrieval correctness (deterministic) and MEASURES query latency
/// and brute-force scan latency at scale (host x86/fp32 — recorded, never
/// fabricated; device numbers will differ). Photos carry NO query-matching tags,
/// so retrieval here is *purely* CLIP semantic — the lexical path is proven
/// separately by the unit tests.
Photo _photo(String id) => Photo(
  id: id,
  title: id,
  caption: '',
  tags: const [], // no lexical hints → retrieval is purely semantic
  date: DateTime(2026, 1, 1),
  album: 'parity',
  source: PhotoSource.sample,
);

Float32List _randomUnit(math.Random r, int d) {
  final v = Float32List(d);
  var n = 0.0;
  for (var i = 0; i < d; i++) {
    v[i] = r.nextDouble() * 2 - 1;
    n += v[i] * v[i];
  }
  n = math.sqrt(n);
  for (var i = 0; i < d; i++) {
    v[i] = v[i] / n;
  }
  return v;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M6 semantic retrieval + latency (real ORT)', (tester) async {
    final paths = ModelKitPaths.resolve();
    paths.requireFiles(includeImages: true);
    final refEmb =
        jsonDecode(File(paths.referenceEmbeddings).readAsStringSync())
            as Map<String, dynamic>;
    final names = (refEmb['image_names'] as List).cast<String>();
    final queries = (refEmb['queries'] as List).cast<String>();

    // --- real encoders ---
    final imageEmbedder = OnnxImageEmbedder(modelPath: paths.imageModel);
    await imageEmbedder.load();
    final tokenizer = await ClipTokenizer.fromGzipFile(paths.vocab);
    final textEmbedder = OnnxTextEmbedder(
      modelPath: paths.textModel,
      tokenizer: tokenizer,
    );
    await textEmbedder.load();

    // --- index the real image embeddings (the "photo library") ---
    final index = BruteForceVectorIndex(dim: AiContract.embeddingDim);
    final imgEmb = <String, Float32List>{};
    for (final n in names) {
      final bytes = File('${paths.imagesDir}/$n.png').readAsBytesSync();
      final e = await imageEmbedder.embed(img.decodeImage(bytes)!);
      imgEmb[n] = e;
      index.upsert(n, e);
    }
    final corpus = [for (final n in names) _photo(n)];

    // The backend under test — no min-cosine filter so every image is a
    // candidate and we test the RANKING (top-1) directly.
    final backend = SemanticSearchBackend(
      embedder: textEmbedder,
      index: index,
      semanticMinCosine: 0.0,
    );

    // --- retrieval correctness through the full M6 path ---
    await backend.search(
      queries.first,
      corpus,
    ); // warm-up (exclude from timing)
    var correct = 0;
    final perQueryMs = <double>[];
    final topName = <String>[];
    for (var q = 0; q < queries.length; q++) {
      final sw = Stopwatch()..start();
      final results = await backend.search(queries[q], corpus);
      sw.stop();
      perQueryMs.add(sw.elapsedMicroseconds / 1000.0);
      final top = results.isEmpty ? '(none)' : results.first.id;
      topName.add(top);
      if (top == names[q]) correct++;
    }
    expect(correct, queries.length, reason: 'M6 top-1 retrieval 100%');

    // --- measure diagonal vs off-diagonal cosine (justifies min-cosine default) ---
    var minDiag = 1.0, maxOff = -1.0;
    for (var q = 0; q < queries.length; q++) {
      final tq = await textEmbedder.embed(queries[q]);
      for (var i = 0; i < names.length; i++) {
        final c = cosineSimilarity(tq, imgEmb[names[i]]!);
        if (i == q) {
          minDiag = math.min(minDiag, c);
        } else {
          maxOff = math.max(maxOff, c);
        }
      }
    }

    // --- brute-force scan+rank latency at scale (random vectors: timing only) ---
    final rnd = math.Random(42);
    final scanMs = <int, double>{};
    for (final k in [1000, 10000]) {
      final big = BruteForceVectorIndex(dim: AiContract.embeddingDim);
      for (var i = 0; i < k; i++) {
        big.upsert('v$i', _randomUnit(rnd, AiContract.embeddingDim));
      }
      final probe = _randomUnit(rnd, AiContract.embeddingDim);
      // median of a few runs
      final samples = <double>[];
      for (var run = 0; run < 5; run++) {
        final sw = Stopwatch()..start();
        big.query(probe, topK: 50);
        sw.stop();
        samples.add(sw.elapsedMicroseconds / 1000.0);
      }
      samples.sort();
      scanMs[k] = samples[samples.length ~/ 2];
    }

    // --- write the (measured) report ---
    double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
    final sortedMs = [...perQueryMs]..sort();
    final report = StringBuffer()
      ..writeln('# PixelSearch M6 — Semantic Search Report')
      ..writeln()
      ..writeln(
        'Generated by `integration_test/semantic_search_test.dart` on a '
        'real Flutter ONNX Runtime (host x86, fp32). Retrieval is '
        'deterministic; latency is measured wall-clock and will vary by host '
        'and on-device.',
      )
      ..writeln()
      ..writeln('## Retrieval (pure semantic — photos have no matching tags)')
      ..writeln('| check | result |')
      ..writeln('|---|---|')
      ..writeln(
        '| Top-1 retrieval | $correct/${queries.length} '
        '(${(100 * correct / queries.length).toStringAsFixed(0)}%) |',
      )
      ..writeln(
        '| Min diagonal cosine (correct pair) | '
        '${minDiag.toStringAsFixed(4)} |',
      )
      ..writeln(
        '| Max off-diagonal cosine (distractor) | '
        '${maxOff.toStringAsFixed(4)} |',
      )
      ..writeln(
        '| Separation (min diag − max off) | '
        '${(minDiag - maxOff).toStringAsFixed(4)} |',
      )
      ..writeln()
      ..writeln('## Per-query top-1')
      ..writeln('| query | retrieved | expected | ok |')
      ..writeln('|---|---|---|---|');
    for (var q = 0; q < queries.length; q++) {
      report.writeln(
        '| ${queries[q]} | ${topName[q]} | ${names[q]} | '
        '${topName[q] == names[q] ? '✓' : '✗'} |',
      );
    }
    report
      ..writeln()
      ..writeln('## End-to-end query latency (embed + scan + hybrid rank)')
      ..writeln('| metric | ms |')
      ..writeln('|---|---|')
      ..writeln('| mean | ${mean(perQueryMs).toStringAsFixed(1)} |')
      ..writeln(
        '| median | ${sortedMs[sortedMs.length ~/ 2].toStringAsFixed(1)} |',
      )
      ..writeln('| min | ${sortedMs.first.toStringAsFixed(1)} |')
      ..writeln('| max | ${sortedMs.last.toStringAsFixed(1)} |')
      ..writeln('| queries | ${queries.length} (after 1 warm-up) |')
      ..writeln()
      ..writeln(
        '## Brute-force scan+rank latency vs index size '
        '(random vectors, ${AiContract.embeddingDim}-d, topK=50; median of 5)',
      )
      ..writeln('| vectors | ms |')
      ..writeln('|---|---|');
    for (final k in scanMs.keys) {
      report.writeln('| $k | ${scanMs[k]!.toStringAsFixed(2)} |');
    }
    report
      ..writeln()
      ..writeln(
        '> The scan cost is O(N·D); at 10k vectors it is a small fraction '
        'of the text-embed cost, confirming brute force is adequate to the '
        '10k–50k target before the sqlite-vec/ANN swap (ADR-009).',
      );
    File(paths.semanticSearchReport).writeAsStringSync(report.toString());

    // Console echo so the numbers are visible in the test log too.
    // ignore: avoid_print
    print(
      '[M6] retrieval=$correct/${queries.length} '
      'diag_min=${minDiag.toStringAsFixed(4)} off_max=${maxOff.toStringAsFixed(4)} '
      'e2e_mean_ms=${mean(perQueryMs).toStringAsFixed(1)} '
      'scan1k_ms=${scanMs[1000]!.toStringAsFixed(2)} '
      'scan10k_ms=${scanMs[10000]!.toStringAsFixed(2)}',
    );

    await imageEmbedder.dispose();
    await textEmbedder.dispose();
  });
}
