import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pixelsearch/ai/clip_tokenizer.dart';
import 'package:pixelsearch/ai/image_embedder.dart';
import 'package:pixelsearch/ai/text_embedder.dart';
import 'package:pixelsearch/benchmark/benchmark.dart';

/// M4.5 — AI core benchmarks via real Flutter ONNX Runtime.
///
/// Platform is the **build host** (x86-64 CPU, fp32, onnxruntime 1.15). These are
/// real measurements but NOT target-device numbers — Android NNAPI/XNNPACK fp16
/// differs and is measured on device. Writes a deterministic-structure report.
const String _base = '/home/claude/PixelSearch_ModelKit';
const String imgModel = '$_base/out/mobileclip_image.onnx';
const String txtModel = '$_base/out/mobileclip_text.onnx';
const String vocab = '$_base/out/bpe_simple_vocab_16e6.txt.gz';
const String images = '$_base/parity/images';
const String report = '$_base/parity/BENCHMARK_REPORT.md';

String _ms(double us) => '${(us / 1000).toStringAsFixed(1)} ms';

String _dur(double ms) {
  if (ms < 1000) return '${ms.toStringAsFixed(0)} ms';
  final s = ms / 1000.0;
  if (s < 90) return '${s.toStringAsFixed(1)} s';
  return '${(s / 60).toStringAsFixed(1)} min';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI core benchmarks (build-host CPU, fp32)', (tester) async {
    final rssStart = ProcessInfo.currentRss;

    // --- model load time ---
    final imageEmbedder = OnnxImageEmbedder(modelPath: imgModel);
    var sw = Stopwatch()..start();
    await imageEmbedder.load();
    final imgLoadMs = (sw..stop()).elapsedMilliseconds;

    final tokenizer = await ClipTokenizer.fromGzipFile(vocab);
    final textEmbedder = OnnxTextEmbedder(modelPath: txtModel, tokenizer: tokenizer);
    sw = Stopwatch()..start();
    await textEmbedder.load();
    final txtLoadMs = (sw..stop()).elapsedMilliseconds;

    final rssAfterLoad = ProcessInfo.currentRss;

    final names = ['cat', 'coffee', 'rocket', 'astronaut', 'camera_person', 'horse'];
    final decoded = {
      for (final n in names)
        n: img.decodeImage(File('$images/$n.png').readAsBytesSync())!
    };

    // --- latency (session reused) ---
    final bench = Benchmark();
    final imgStats = await bench.measure(
        'image_embed', () => imageEmbedder.embed(decoded['astronaut']!),
        iterations: 30, warmup: 5);
    final txtStats = await bench.measure('text_embed',
        () => textEmbedder.embed('a person riding a horse on the beach'),
        iterations: 30, warmup: 5);

    // --- batch throughput (image encoder) ---
    const rounds = 10;
    sw = Stopwatch()..start();
    for (var k = 0; k < rounds; k++) {
      for (final n in names) {
        await imageEmbedder.embed(decoded[n]!);
      }
    }
    final batchMs = (sw..stop()).elapsedMilliseconds;
    final totalImgs = rounds * names.length;
    final imgsPerSec = totalImgs * 1000.0 / batchMs;

    // --- projections from measured mean image latency ---
    final perImgMs = imgStats.meanUs / 1000.0;
    final perTxtMs = txtStats.meanUs / 1000.0;
    final rssMb = (rssAfterLoad - rssStart) / 1e6;
    const sizes = [100, 1000, 5000, 10000, 50000];

    final b = StringBuffer()
      ..writeln('# PixelSearch AI — Benchmark Report')
      ..writeln()
      ..writeln('Platform: **build host — x86-64 CPU, fp32, onnxruntime 1.15** via real Flutter ONNX '
          'Runtime. These are real measurements but **not** target-device numbers; Android NNAPI/'
          'XNNPACK fp16 is measured on device (still pending).')
      ..writeln()
      ..writeln('## Model loading & memory')
      ..writeln('| metric | value |')
      ..writeln('|---|---|')
      ..writeln('| Image encoder load (fp32, 87 MB) | $imgLoadMs ms |')
      ..writeln('| Text encoder load (fp32, 254 MB) | $txtLoadMs ms |')
      ..writeln('| Process RSS increase after loading both | ${rssMb.toStringAsFixed(0)} MB |')
      ..writeln('| Session reuse | loaded once; every embed below reuses the session (no reload) |')
      ..writeln()
      ..writeln('## Embedding latency (session reused, ${imgStats.iterations} iterations)')
      ..writeln('| op | mean | median | p95 | min | max |')
      ..writeln('|---|---|---|---|---|---|')
      ..writeln('| image embed | ${_ms(imgStats.meanUs)} | ${_ms(imgStats.medianUs)} | '
          '${_ms(imgStats.p95Us)} | ${_ms(imgStats.minUs)} | ${_ms(imgStats.maxUs)} |')
      ..writeln('| text embed | ${_ms(txtStats.meanUs)} | ${_ms(txtStats.medianUs)} | '
          '${_ms(txtStats.p95Us)} | ${_ms(txtStats.minUs)} | ${_ms(txtStats.maxUs)} |')
      ..writeln()
      ..writeln('## Throughput & single-thread indexing projection (image encoder)')
      ..writeln('Measured image throughput: **${imgsPerSec.toStringAsFixed(1)} img/s** '
          'over $totalImgs embeds. Query (text) embed ≈ ${perTxtMs.toStringAsFixed(1)} ms.')
      ..writeln()
      ..writeln('Projected full-index time = N × mean image latency '
          '(${perImgMs.toStringAsFixed(1)} ms), single isolate:')
      ..writeln('| gallery size | projected index time (1 isolate) |')
      ..writeln('|---|---|');
    for (final n in sizes) {
      b.writeln('| ${n.toString().padLeft(6)} | ${_dur(n * perImgMs)} |');
    }
    b
      ..writeln()
      ..writeln('_Note: M5 runs indexing in a background isolate with batching; multi-core devices '
          'reduce wall-clock roughly linearly. Search latency (M6) is added when the search path exists._');

    File(report).writeAsStringSync(b.toString());
    // ignore: avoid_print
    print(b.toString());

    await imageEmbedder.dispose();
    await textEmbedder.dispose();

    expect(imgStats.iterations, 30);
    expect(imgsPerSec, greaterThan(0));
  });
}
