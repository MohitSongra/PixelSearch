import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/ai_contract.dart';
import '../domain/search/search_diagnostics.dart';
import '../models/photo.dart';
import 'retrieval_evaluation.dart';

Map<String, Object?> corpusSnapshot(
  List<Photo> corpus,
  Map<String, Float32List> vectors,
) {
  final ordered = [...corpus]..sort((a, b) => a.id.compareTo(b.id));
  final norms = <double>[];
  final invalid = <String>[];
  final rows = [
    for (final p in ordered)
      {
        'id': p.id,
        'filename': p.assetName,
        'album': p.album,
        'title': p.title,
        'caption': p.caption,
        'tags': p.tags,
        'labels': p.labels,
        'face_count': p.faceCount,
        'place': p.place,
        'date_ms': p.date.millisecondsSinceEpoch,
      },
  ];
  final vectorRows = <Map<String, Object>>[];
  final ids = vectors.keys.toList()..sort();
  for (final id in ids) {
    final vector = vectors[id]!;
    final norm = math.sqrt(vector.fold<double>(0, (sum, v) => sum + v * v));
    if (vector.length != AiContract.embeddingDim ||
        !norm.isFinite ||
        (norm - 1).abs() > 0.001) {
      invalid.add(id);
    } else {
      norms.add(norm);
    }
    vectorRows.add({
      'id': id,
      'bytes': base64Encode(
        vector.buffer.asUint8List(vector.offsetInBytes, vector.lengthInBytes),
      ),
    });
  }
  return {
    'photo_count': corpus.length,
    'vector_count': vectors.length,
    'metadata_sha256': sha256.convert(utf8.encode(jsonEncode(rows))).toString(),
    'vectors_sha256': sha256
        .convert(utf8.encode(jsonEncode(vectorRows)))
        .toString(),
    'invalid_vector_ids': invalid,
    'norm_min': norms.isEmpty ? null : norms.reduce(math.min),
    'norm_max': norms.isEmpty ? null : norms.reduce(math.max),
    'model_id': AiContract.modelId,
    'embedding_version': AiContract.embeddingVersion,
    'artifact_version_contract': AiContract.artifactVersion,
    'per_row_artifact_provenance':
        '[MISSING] rows store model/embedding version, not artifact hash',
    'photos': rows,
  };
}

Future<Map<String, Object?>> runSearchEvaluation({
  required SearchInspector inspector,
  required List<Photo> corpus,
  required Map<String, Float32List> vectors,
  required EvaluationDataset dataset,
  void Function(int, int)? onProgress,
}) async {
  final snapshot = corpusSnapshot(corpus, vectors);
  if ((snapshot['invalid_vector_ids'] as List).isNotEmpty) {
    throw StateError(
      'Invalid image vectors: ${snapshot['invalid_vector_ids']}',
    );
  }
  // Validate every label before running models or publishing a partial score table.
  for (final query in dataset.queries) {
    resolveJudgments(query, corpus);
  }
  final reports = <Map<String, Object?>>[];
  for (final query in dataset.queries) {
    final trace = await inspector.inspect(query.query, corpus);
    reports.add({
      'case': query.toJson(),
      'trace': trace.toJson(),
      'comparison': rankingComparison(trace),
      'evaluation': evaluateTrace(trace, query, corpus),
    });
    onProgress?.call(reports.length, dataset.queries.length);
    await Future<void>.delayed(Duration.zero);
  }
  return {
    'schema_version': 1,
    'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
    'dataset_id': dataset.id,
    'dataset_sha256': sha256
        .convert(utf8.encode(jsonEncode(dataset.toJson())))
        .toString(),
    'snapshot': snapshot,
    'query_count': reports.length,
    'labelled_query_count': dataset.queries
        .where((q) => q.judgments.isNotEmpty)
        .length,
    'timing_scope':
        'Single measured samples; full scan shared across replays. Policy timings exclude embedding and trace serialization. Not independent end-to-end benchmarks.',
    'production_policy_changed': false,
    'queries': reports,
  };
}
