import 'face_grouping.dart';

/// Inputs for ordering unnamed faces by similarity to one person's confirmed
/// faces. Only the user confirms identities; this never assigns anything.
class FaceSuggestionInput {
  const FaceSuggestionInput({
    required this.references,
    required this.candidates,
    this.occupiedPhotoIds = const {},
    this.rejectedFaceIds = const {},
    this.limit = 60,
  });

  /// Faces the user assigned to the person (manual assignments only).
  final List<FaceVector> references;

  /// Unassigned, not dismissed faces with descriptors.
  final List<FaceVector> candidates;

  /// Photos that already show the person.
  final Set<String> occupiedPhotoIds;

  /// Faces the user said are not this person.
  final Set<String> rejectedFaceIds;
  final int limit;
}

class FaceSuggestion {
  const FaceSuggestion({
    required this.faceId,
    required this.photoId,
    required this.nearestFaceId,
    required this.similarity,
    required this.support,
  });
  final String faceId, photoId, nearestFaceId;

  /// Ordering keys only: never displayed, never compared with a cutoff.
  final double similarity, support;
}

class FaceSuggestionResult {
  const FaceSuggestionResult({
    this.items = const [],
    this.eligible = 0,
    this.references = 0,
  });
  final List<FaceSuggestion> items;

  /// Candidates left after the per-photo and rejection rules.
  final int eligible;

  /// Usable confirmed faces of the person.
  final int references;
}

/// Orders candidates by their nearest confirmed face (max cosine), breaking
/// ties by the mean of the top three cosines, then by face id.
///
/// A centroid would blur a person's different looks (pose, glasses, age) into
/// a point no real face is near; the nearest confirmed face asks the question
/// the user can answer. There is deliberately no threshold: on the test phone
/// same- and different-person scores overlap, so any cutoff would be an
/// unvalidated recognition decision.
FaceSuggestionResult rankFaceSuggestions(FaceSuggestionInput input) {
  if (input.limit < 1) throw ArgumentError.value(input.limit, 'limit');
  final references =
      input.references.where((f) => validFaceVector(f.vector)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  if (references.isEmpty) return const FaceSuggestionResult();
  final referenceIds = {for (final r in references) r.id};
  final candidates =
      input.candidates
          .where(
            (c) =>
                validFaceVector(c.vector) &&
                !referenceIds.contains(c.id) &&
                !input.rejectedFaceIds.contains(c.id) &&
                !input.occupiedPhotoIds.contains(c.photoId),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  int compare(FaceSuggestion a, FaceSuggestion b) {
    final bySimilarity = b.similarity.compareTo(a.similarity);
    if (bySimilarity != 0) return bySimilarity;
    final bySupport = b.support.compareTo(a.support);
    return bySupport != 0 ? bySupport : a.faceId.compareTo(b.faceId);
  }

  final bestPerPhoto = <String, FaceSuggestion>{};
  for (final candidate in candidates) {
    final scores = <double>[];
    var best = double.negativeInfinity;
    var nearest = references.first.id;
    for (final reference in references) {
      final score = faceCosine(candidate.vector, reference.vector);
      scores.add(score);
      if (score > best) {
        best = score;
        nearest = reference.id;
      }
    }
    scores.sort((a, b) => b.compareTo(a));
    final top = scores.take(3).toList();
    final suggestion = FaceSuggestion(
      faceId: candidate.id,
      photoId: candidate.photoId,
      nearestFaceId: nearest,
      similarity: best,
      support: top.reduce((a, b) => a + b) / top.length,
    );
    final current = bestPerPhoto[candidate.photoId];
    if (current == null || compare(suggestion, current) < 0) {
      bestPerPhoto[candidate.photoId] = suggestion;
    }
  }
  final ordered = bestPerPhoto.values.toList()..sort(compare);
  return FaceSuggestionResult(
    items: ordered.take(input.limit).toList(),
    eligible: ordered.length,
    references: references.length,
  );
}
