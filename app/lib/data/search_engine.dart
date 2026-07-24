import '../models/photo.dart';

/// A lightweight, on-device *mock* of semantic search.
///
/// This ranks photos by matching query terms against each photo's tags,
/// caption, place and album. It is a stand-in that makes the UI feel
/// end-to-end for the review. In the real product (Milestones M4–M7) this
/// function is replaced by: CLIP text-embedding of the query + cosine
/// similarity over on-device photo embeddings + this keyword boost.
List<Photo> searchPhotos(List<Photo> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final scored = <(Photo, int)>[];

  for (final p in all) {
    var score = 0;
    final blob = p.searchBlob;
    for (final t in terms) {
      if (p.tags.contains(t)) {
        score += 3; // exact tag hit
      } else if (p.tags.any((tag) => tag.contains(t))) {
        score += 2; // partial tag hit
      } else if (blob.contains(t)) {
        score += 1; // caption/place/album hit
      }
    }
    if (score > 0) scored.add((p, score));
  }

  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    return b.$1.date.compareTo(a.$1.date);
  });
  return scored.map((e) => e.$1).toList();
}

/// The matched terms for a photo — used by the viewer's "why this matched" chip row.
List<String> matchedTags(Photo p, String query) {
  final terms = query.toLowerCase().split(RegExp(r'\s+')).toSet();
  return p.tags.where((tag) => terms.any((t) => t.isNotEmpty && tag.contains(t))).toList();
}
