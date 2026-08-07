import 'dart:typed_data';

import '../../domain/search/vector_index.dart';

/// Exact cosine search by linear scan over in-memory embeddings.
///
/// O(N·D) per query — perfectly adequate to ~50k vectors (ADR-008). When a
/// library outgrows that, swap in a `SqliteVecVectorIndex` (or ObjectBox HNSW)
/// behind [VectorIndex]; every caller stays unchanged (ADR-009).
///
/// Assumes L2-normalized vectors ⇒ cosine = dot product (INTERFACE_CONTRACT §5).
class BruteForceVectorIndex implements VectorIndex {
  BruteForceVectorIndex({this.dim = 512});

  final int dim;
  final Map<String, Float32List> _vectors = {};

  @override
  int get length => _vectors.length;

  @override
  void upsert(String id, Float32List vector) {
    assert(vector.length == dim,
        'expected a $dim-d vector, got ${vector.length}');
    _vectors[id] = vector;
  }

  @override
  void remove(String id) => _vectors.remove(id);

  @override
  void clear() => _vectors.clear();

  @override
  List<VectorMatch> query(Float32List query, {int topK = 50}) {
    assert(query.length == dim,
        'expected a $dim-d query, got ${query.length}');
    final matches = <VectorMatch>[
      for (final e in _vectors.entries) VectorMatch(e.key, _dot(query, e.value)),
    ];
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.length > topK ? matches.sublist(0, topK) : matches;
  }

  static double _dot(Float32List a, Float32List b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }
}
