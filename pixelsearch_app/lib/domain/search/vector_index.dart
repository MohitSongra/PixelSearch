import 'dart:typed_data';

/// A ranked hit from a [VectorIndex]: a photo id and its similarity score
/// (higher = more similar).
class VectorMatch {
  const VectorMatch(this.id, this.score);
  final String id;
  final double score;
}

/// Abstraction over a similarity index of embeddings.
///
/// This is the seam that future-proofs search: the current [BruteForceVectorIndex]
/// (exact linear scan) can be replaced by an ANN backend (sqlite-vec, ObjectBox
/// HNSW, …) that implements this same interface, with **no change** to any caller
/// — the M6 search service, repositories, domain, and UI all depend only on this
/// contract. See ADR-009.
///
/// Vectors are assumed **L2-normalized** (INTERFACE_CONTRACT.md §5), so cosine
/// similarity is a plain dot product.
abstract interface class VectorIndex {
  /// Number of vectors currently indexed.
  int get length;

  /// Insert or replace the vector stored under [id].
  void upsert(String id, Float32List vector);

  /// Remove [id] if present.
  void remove(String id);

  /// Remove all vectors.
  void clear();

  /// The [topK] ids most similar to [query], descending by score. [query] must
  /// be L2-normalized and the same dimension as the indexed vectors.
  List<VectorMatch> query(
    Float32List query, {
    int topK = 50,
    Set<String>? eligibleIds,
  });
}
