import '../domain/search/query_terms.dart';
import '../models/photo.dart';

export '../domain/search/query_terms.dart' show queryTerms;

/// Lexical relevance of one photo to the given (already-normalized) [terms].
///
/// This is the single source of truth for keyword scoring, shared by
/// [KeywordSearchBackend] (the fallback) and the M6 [HybridScorer] (the lexical
/// component of the hybrid blend). Higher is better; 0 means "no lexical match".
///
/// Keyword-only fallback keeps ML Kit labels by default. Semantic-hybrid
/// ranking passes [includeLabels] as false because labels are enrichment, not
/// evidence strong enough to override image/text similarity.
///
/// Signal priority per term: an exact tag hit (3) beats a partial tag hit or an
/// exact ML Kit label hit (2), which beats a substring hit anywhere in the
/// caption/place/album/label blob (1).
double keywordScore(
  Photo p,
  List<String> terms, {
  bool includeLabels = true,
}) {
  var score = 0.0;
  final blob = includeLabels ? p.searchBlob : p.metadataSearchBlob;
  for (final t in terms) {
    if (p.tags.contains(t)) {
      score += 3; // exact tag hit
    } else if (p.tags.any((tag) => tag.contains(t))) {
      score += 2; // partial tag hit
    } else if (includeLabels && p.labels.contains(t)) {
      score += 2; // exact ML Kit object-label hit
    } else if (blob.contains(t)) {
      score += 1; // caption/place/album/label substring hit
    }
  }
  return score;
}

/// A lightweight, on-device keyword search over photo metadata.
///
/// Ranks photos by [keywordScore] over their tags/labels/caption/place/album.
/// This is the pre-AI fallback that also runs on web (no ONNX): the real
/// product ranks with CLIP embeddings first and uses this only as the lexical
/// component (M6 [HybridScorer]) or when the model is unavailable.
List<Photo> searchPhotos(List<Photo> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  final terms = queryTerms(q);
  final scored = <(Photo, double)>[];
  for (final p in all) {
    final score = keywordScore(p, terms);
    if (score > 0) scored.add((p, score));
  }

  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    return b.$1.date.compareTo(a.$1.date);
  });
  return scored.map((e) => e.$1).toList();
}
