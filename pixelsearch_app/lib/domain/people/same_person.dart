import 'dart:typed_data';

import 'face_grouping.dart';

/// What a "Same person?" card asks.
enum SamePersonKind {
  /// Automatic grouping added this face to a named person: "Is this (name)?".
  verifyAutomatic,

  /// Two groups kept apart by grouping may be one person: "Same person?".
  mergeGroups,
}

enum SamePersonAnswer { yes, no, notSure }

/// One face group (a named person or an unnamed group) as seen by the
/// question builder.
class FaceGroupInput {
  const FaceGroupInput({
    required this.personId,
    required this.named,
    required this.faces,
    this.photoIds = const {},
    this.confirmedFaceIds = const [],
    this.size = 0,
  });
  final String personId;
  final bool named;

  /// Faces of the group that have a usable descriptor.
  final List<FaceVector> faces;

  /// Every photo the group appears in (including faces without descriptors).
  final Set<String> photoIds;

  /// Faces the user assigned (any size); verification compares with these.
  final List<String> confirmedFaceIds;

  /// Number of faces in the group.
  final int size;
}

class SamePersonQuestion {
  const SamePersonQuestion({
    required this.kind,
    required this.leftPersonId,
    required this.leftFaceId,
    required this.rightFaceId,
    this.rightPersonId,
    this.similarity = 0,
  });
  final SamePersonKind kind;

  /// The named person (verify) or the first group (merge).
  final String leftPersonId;
  final String leftFaceId;

  /// The second group; null for [SamePersonKind.verifyAutomatic].
  final String? rightPersonId;

  /// The automatic face (verify) or the closest face of the second group.
  final String rightFaceId;

  /// Ordering key; never shown. Merge pairs below the user's lowest "same"
  /// review score are not asked ([SamePersonInput.minSimilarity]); it never
  /// decides an identity.
  final double similarity;
}

class SamePersonInput {
  const SamePersonInput({
    this.groups = const [],
    this.automaticFaces = const [],
    this.decided = const {},
    this.minSimilarity,
    this.limit = 20,
  });
  final List<FaceGroupInput> groups;

  /// (person id, face) for faces automatic grouping put into named people.
  final List<(String, FaceVector)> automaticFaces;

  /// face id → person ids the user already answered about (reject or unsure).
  final Map<String, Set<String>> decided;

  /// Group pairs whose closest faces score below this are not asked about. It
  /// comes from the user's own review (the lowest-scoring pair they judged the
  /// same person); it decides which questions to ask, never an identity.
  final double? minSimilarity;
  final int limit;
}

/// Builds the "Same person?" questions: first every automatic face in a named
/// person, then pairs of groups ordered by their closest faces. Pairs that
/// share a photo are skipped (one person cannot appear twice in a photo), and
/// pairs the user already answered are never asked again.
List<SamePersonQuestion> buildSamePersonQuestions(SamePersonInput input) {
  if (input.limit < 1) throw ArgumentError.value(input.limit, 'limit');
  bool decided(String faceId, String personId) =>
      input.decided[faceId]?.contains(personId) == true;
  final questions = <SamePersonQuestion>[];
  final byPerson = {for (final g in input.groups) g.personId: g};
  final automatic = [...input.automaticFaces]
    ..sort((a, b) {
      final byPersonId = a.$1.compareTo(b.$1);
      return byPersonId != 0 ? byPersonId : a.$2.id.compareTo(b.$2.id);
    });
  for (final (personId, face) in automatic) {
    if (decided(face.id, personId)) continue;
    // Show the face next to one the user confirmed for that person: the
    // closest one with a descriptor, otherwise any confirmed face.
    final confirmed = [...?byPerson[personId]?.confirmedFaceIds]..sort();
    if (confirmed.isEmpty) continue;
    var best = confirmed.first;
    var bestScore = double.negativeInfinity;
    for (final reference in byPerson[personId]!.faces) {
      if (!confirmed.contains(reference.id) ||
          !validFaceVector(reference.vector) ||
          !validFaceVector(face.vector)) {
        continue;
      }
      final score = faceCosine(face.vector, reference.vector);
      if (score > bestScore ||
          (score == bestScore && reference.id.compareTo(best) < 0)) {
        bestScore = score;
        best = reference.id;
      }
    }
    questions.add(
      SamePersonQuestion(
        kind: SamePersonKind.verifyAutomatic,
        leftPersonId: personId,
        leftFaceId: best,
        rightFaceId: face.id,
        similarity: bestScore,
      ),
    );
  }

  // Validate each descriptor once; the inner loop is a plain dot product.
  final valid = {
    for (final g in input.groups)
      g.personId: g.faces.where((f) => validFaceVector(f.vector)).toList(),
  };
  final groups =
      input.groups.where((g) => valid[g.personId]!.isNotEmpty).toList()
        ..sort((a, b) => a.personId.compareTo(b.personId));
  final pairs = <SamePersonQuestion>[];
  for (var i = 0; i < groups.length; i++) {
    for (var j = i + 1; j < groups.length; j++) {
      var a = groups[i], b = groups[j];
      // Two named people are never merged by a question.
      if (a.named && b.named) continue;
      if (a.photoIds.intersection(b.photoIds).isNotEmpty) continue;
      // The named group (or the larger one) is the anchor on the left.
      if (b.named || (!a.named && b.size > a.size)) (a, b) = (b, a);
      if (b.faces.any((f) => decided(f.id, a.personId)) ||
          a.faces.any((f) => decided(f.id, b.personId))) {
        continue;
      }
      var bestScore = double.negativeInfinity;
      String? left, right;
      for (final x in valid[a.personId]!) {
        for (final y in valid[b.personId]!) {
          final score = _dot(x.vector, y.vector);
          if (score > bestScore) {
            bestScore = score;
            left = x.id;
            right = y.id;
          }
        }
      }
      if (left == null || right == null) continue;
      if (input.minSimilarity != null && bestScore < input.minSimilarity!) {
        continue;
      }
      pairs.add(
        SamePersonQuestion(
          kind: SamePersonKind.mergeGroups,
          leftPersonId: a.personId,
          leftFaceId: left,
          rightPersonId: b.personId,
          rightFaceId: right,
          similarity: bestScore,
        ),
      );
    }
  }
  pairs.sort((x, y) {
    final bySimilarity = y.similarity.compareTo(x.similarity);
    if (bySimilarity != 0) return bySimilarity;
    final byLeft = x.leftPersonId.compareTo(y.leftPersonId);
    return byLeft != 0 ? byLeft : x.rightPersonId!.compareTo(y.rightPersonId!);
  });
  questions.addAll(pairs);
  return questions.take(input.limit).toList();
}

double _dot(Float32List a, Float32List b) {
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum.clamp(-1.0, 1.0);
}
