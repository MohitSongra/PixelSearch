import 'dart:math' as math;
import 'dart:typed_data';

/// L2-normalize [v]. Safe on already-normalized inputs (idempotent) and on the
/// zero vector (returned unchanged). The MobileCLIP encoders already normalize
/// internally, so this is the explicit, defensive final step of the pipeline.
Float32List l2Normalize(Float32List v) {
  var sum = 0.0;
  for (final x in v) {
    sum += x * x;
  }
  final norm = math.sqrt(sum);
  if (norm == 0) return Float32List.fromList(v);
  final out = Float32List(v.length);
  for (var i = 0; i < v.length; i++) {
    out[i] = v[i] / norm;
  }
  return out;
}

/// Cosine similarity. For L2-normalized inputs this equals the dot product
/// (INTERFACE_CONTRACT.md §5).
double cosineSimilarity(Float32List a, Float32List b) {
  assert(a.length == b.length, 'dimension mismatch: ${a.length} vs ${b.length}');
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  final denom = math.sqrt(na) * math.sqrt(nb);
  return denom == 0 ? 0.0 : dot / denom;
}
