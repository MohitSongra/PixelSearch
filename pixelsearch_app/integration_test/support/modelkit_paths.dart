import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates the external ModelKit fixtures used by host-only real-ORT tests.
///
/// A standard two-repository checkout puts `model_kit` next to
/// `pixelsearch_app`. Set `PIXELSEARCH_MODELKIT` when the kit lives elsewhere.
class ModelKitPaths {
  ModelKitPaths._(this.root);

  final String root;

  factory ModelKitPaths.resolve({
    String? environmentValue,
    String? workingDirectory,
  }) {
    final configured =
        environmentValue ?? Platform.environment['PIXELSEARCH_MODELKIT'];
    final base = configured != null && configured.trim().isNotEmpty
        ? configured.trim()
        : p.join(workingDirectory ?? Directory.current.path, '..', 'model_kit');
    return ModelKitPaths._(p.normalize(base));
  }

  String get imageModel => p.join(root, 'out', 'mobileclip_image.onnx');
  String get textModel => p.join(root, 'out', 'mobileclip_text.onnx');
  String get vocab => p.join(root, 'out', 'bpe_simple_vocab_16e6.txt.gz');
  String get parityDir => p.join(root, 'parity');
  String get imagesDir => p.join(parityDir, 'images');
  String get referenceEmbeddings =>
      p.join(parityDir, 'reference_embeddings.json');
  String get referenceVectors => p.join(root, 'out', 'reference_vectors.json');
  String get benchmarkReport => p.join(parityDir, 'BENCHMARK_REPORT.md');
  String get semanticSearchReport =>
      p.join(parityDir, 'SEMANTIC_SEARCH_REPORT.md');
  String get validationReport => p.join(parityDir, 'VALIDATION_REPORT.md');

  /// Fails early with an actionable message instead of an unrelated file error.
  void requireFiles({
    bool includeImages = false,
    bool includeReferenceVectors = false,
  }) {
    final required = <String>[
      imageModel,
      textModel,
      vocab,
      referenceEmbeddings,
      if (includeReferenceVectors) referenceVectors,
    ];
    if (includeImages) {
      required.addAll([
        for (final name in _parityImageNames) p.join(imagesDir, '$name.png'),
      ]);
    }
    final missing = required.where((path) => !File(path).existsSync()).toList();
    if (missing.isEmpty) return;

    throw StateError(
      'Missing ModelKit fixtures:\n${missing.join('\n')}\n'
      'Set PIXELSEARCH_MODELKIT to the ModelKit root, or use a checkout where '
      'model_kit is a sibling of pixelsearch_app.',
    );
  }

  static const _parityImageNames = [
    'cat',
    'coffee',
    'rocket',
    'astronaut',
    'camera_person',
    'horse',
  ];
}
