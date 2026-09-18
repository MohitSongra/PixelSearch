import '../../models/photo.dart';

class LibrarySuggestion {
  const LibrarySuggestion(this.query, this.photoCount);
  final String query;
  final int photoCount;
}

/// Suggestions describe stored labels, not invented relationships or captions.
List<LibrarySuggestion> librarySuggestions(
  Iterable<Photo> photos, {
  int limit = 8,
}) {
  const generic = {
    'photo',
    'photograph',
    'photography',
    'image',
    'date',
    'portrait',
    'landscape',
    'cool',
    'fun',
    'event',
    'beauty',
    'snapshot',
  };
  final counts = <String, int>{};
  for (final photo in photos) {
    final labels = photo.labels
        .map(
          (label) => label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
        )
        .where(
          (label) =>
              label.length >= 2 &&
              label.length <= 40 &&
              !generic.contains(label),
        )
        .toSet();
    for (final label in labels) {
      counts.update(label, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final frequency = b.value.compareTo(a.value);
      return frequency != 0 ? frequency : a.key.compareTo(b.key);
    });
  return List.unmodifiable(
    sorted
        .take(limit < 0 ? 0 : limit)
        .map((entry) => LibrarySuggestion(entry.key, entry.value)),
  );
}
