import 'dart:math' as math;
import 'dart:typed_data';

import 'face_contract.dart';

class FaceVector {
  const FaceVector({
    required this.id,
    required this.photoId,
    required this.vector,
    this.personId,
    this.rejectedPeople = const {},
  });
  final String id, photoId;
  final Float32List vector;
  final String? personId;
  final Set<String> rejectedPeople;
}

bool validFaceVector(List<double> v) {
  if (v.length != FaceContract.dimensions || v.any((x) => !x.isFinite)) {
    return false;
  }
  final norm = v.fold<double>(0, (sum, x) => sum + x * x);
  return (norm - 1).abs() <= 0.002;
}

double faceCosine(List<double> a, List<double> b) {
  if (!validFaceVector(a) || !validFaceVector(b)) {
    throw const FormatException(
      'Face descriptor is not finite and normalized.',
    );
  }
  return _unitDot(a, b);
}

double _unitDot(List<double> a, List<double> b) {
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum.clamp(-1.0, 1.0);
}

/// Admission is complete-link, not single-link union-find. A bridge face can
/// never fuse established identities; multiple eligible groups mean ambiguity.
Map<String, String?> groupFaces(
  List<FaceVector> faces,
  double threshold, {
  Map<String, Set<String>> personPhotos = const {},
}) {
  if (!threshold.isFinite || threshold < -1 || threshold > 1) {
    throw ArgumentError.value(threshold, 'threshold');
  }
  final ordered = [...faces]..sort((a, b) => a.id.compareTo(b.id));
  final groups = <String, List<FaceVector>>{};
  for (final face in ordered.where((f) => f.personId != null)) {
    if (validFaceVector(face.vector)) {
      groups.putIfAbsent(face.personId!, () => []).add(face);
    }
  }
  final assignments = <String, String?>{};
  for (final face in ordered.where((f) => f.personId == null)) {
    if (!validFaceVector(face.vector)) continue;
    String? candidate;
    var ambiguous = false;
    for (final entry in groups.entries) {
      if (personPhotos[entry.key]?.contains(face.photoId) == true) continue;
      if (face.rejectedPeople.contains(entry.key)) continue;
      var qualifies = true;
      for (final member in entry.value) {
        if (member.photoId == face.photoId ||
            _unitDot(face.vector, member.vector) < threshold) {
          qualifies = false;
          break;
        }
      }
      if (!qualifies) continue;
      if (candidate != null) {
        ambiguous = true;
        break;
      }
      candidate = entry.key;
    }
    if (ambiguous) {
      assignments[face.id] = null;
      continue;
    }
    final personId = candidate ?? 'person:${face.id}';
    // A rejected seed group must not be recreated after a user's removal.
    if (face.rejectedPeople.contains(personId)) {
      assignments[face.id] = null;
      continue;
    }
    groups.putIfAbsent(personId, () => []).add(face);
    assignments[face.id] = personId;
  }
  return assignments;
}

class FacePair {
  const FacePair({
    required this.left,
    required this.right,
    required this.subset,
    required this.cosine,
    this.judgment = 'pending',
  });
  final String left, right, subset, judgment;
  final double cosine;
  String get id => '$left|$right';
}

int _stableHash(String value) => value.codeUnits.fold<int>(
  2166136261,
  (hash, code) => ((hash ^ code) * 16777619) & 0x7fffffff,
);

/// Freeze photo-disjoint subsets before any judgments. A bounded candidate
/// pool mixes nearest, mid-score and distant pairs; no expected labels exist.
List<FacePair> buildFaceReview(List<FaceVector> input) {
  final valid = input.where((f) => validFaceVector(f.vector)).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final result = <FacePair>[];
  for (final subset in ['calibration', 'validation']) {
    final faces = valid
        .where(
          (f) => (_stableHash(f.photoId) % 3 == 0) == (subset == 'validation'),
        )
        .toList();
    final pool = <String, FacePair>{};
    for (var i = 0; i < faces.length; i++) {
      final nearest = <FacePair>[];
      FacePair? distant;
      for (var j = i + 1; j < faces.length; j++) {
        if (faces[i].photoId == faces[j].photoId) continue;
        final pair = FacePair(
          left: faces[i].id,
          right: faces[j].id,
          subset: subset,
          cosine: _unitDot(faces[i].vector, faces[j].vector),
        );
        nearest.add(pair);
        nearest.sort((a, b) => b.cosine.compareTo(a.cosine));
        if (nearest.length > 3) nearest.removeLast();
        if (distant == null || pair.cosine < distant.cosine) distant = pair;
      }
      for (final p in [...nearest, ?distant]) {
        pool[p.id] = p;
      }
    }
    final ranked = pool.values.toList()
      ..sort((a, b) {
        final score = b.cosine.compareTo(a.cosine);
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    final count = math.min(subset == 'calibration' ? 40 : 20, ranked.length);
    // Half the review covers closest matches; the remainder spans score range.
    final selected = <String, FacePair>{};
    for (var i = 0; i < count ~/ 2; i++) {
      selected[ranked[i].id] = ranked[i];
    }
    for (var i = 0; selected.length < count && i < ranked.length; i++) {
      final at = count <= 1
          ? 0
          : (i * (ranked.length - 1) / (count - 1)).round();
      if (at >= ranked.length) break;
      selected[ranked[at].id] = ranked[at];
    }
    for (final p in ranked) {
      if (selected.length >= count) break;
      selected[p.id] = p;
    }
    result.addAll(selected.values);
  }
  return result;
}

class FaceCalibration {
  const FaceCalibration({
    this.threshold,
    required this.reason,
    this.calibrationSame = 0,
    this.calibrationDifferent = 0,
    this.validationSame = 0,
    this.validationDifferent = 0,
    this.calibrationTrueJoins = 0,
    this.validationTrueJoins = 0,
    this.validationFalseJoins = 0,
  });
  final double? threshold;
  final String reason;
  final int calibrationSame,
      calibrationDifferent,
      validationSame,
      validationDifferent,
      calibrationTrueJoins,
      validationTrueJoins,
      validationFalseJoins;
  bool get passed => threshold != null;
  Map<String, Object?> toJson() => {
    'passed': passed,
    'threshold': threshold,
    'reason': reason,
    'calibration_same': calibrationSame,
    'calibration_different': calibrationDifferent,
    'validation_same': validationSame,
    'validation_different': validationDifferent,
    'calibration_true_joins': calibrationTrueJoins,
    'validation_true_joins': validationTrueJoins,
    'validation_false_joins': validationFalseJoins,
  };
}

FaceCalibration calibrateFaces(List<FacePair> pairs) {
  if (pairs.any(
    (p) =>
        !p.cosine.isFinite ||
        p.cosine < -1 ||
        p.cosine > 1 ||
        !['calibration', 'validation'].contains(p.subset) ||
        !['pending', 'same', 'different', 'unsure'].contains(p.judgment),
  )) {
    return const FaceCalibration(
      reason: 'Invalid review data. Automatic assignment is blocked.',
    );
  }
  if (pairs.isEmpty || pairs.any((p) => p.judgment == 'pending')) {
    return const FaceCalibration(
      reason: 'Complete the frozen pair review first.',
    );
  }
  final c = pairs.where((p) => p.subset == 'calibration').toList();
  final v = pairs.where((p) => p.subset == 'validation').toList();
  int count(List<FacePair> p, String label) =>
      p.where((p) => p.judgment == label).length;
  final cs = count(c, 'same'), cd = count(c, 'different');
  final vs = count(v, 'same'), vd = count(v, 'different');
  FaceCalibration result(
    String reason, {
    double? threshold,
    int ct = 0,
    int vt = 0,
    int vf = 0,
  }) => FaceCalibration(
    reason: reason,
    threshold: threshold,
    calibrationSame: cs,
    calibrationDifferent: cd,
    validationSame: vs,
    validationDifferent: vd,
    calibrationTrueJoins: ct,
    validationTrueJoins: vt,
    validationFalseJoins: vf,
  );
  if ([cs, cd, vs, vd].any((n) => n == 0)) {
    return result(
      'Both subsets need Same person and Different people judgments.',
    );
  }
  double? best;
  var bestTrue = 0;
  final thresholds =
      c.where((p) => p.judgment == 'same').map((p) => p.cosine).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
  for (final t in thresholds) {
    if (!t.isFinite || t < -1 || t > 1) continue;
    if (c.any((p) => p.judgment == 'different' && p.cosine >= t)) continue;
    final tp = c.where((p) => p.judgment == 'same' && p.cosine >= t).length;
    if (tp > bestTrue) {
      best = t;
      bestTrue = tp;
    }
  }
  if (best == null) {
    return result('No conservative threshold separated the calibration pairs.');
  }
  final threshold = best;
  final vp = v
      .where((p) => p.judgment == 'same' && p.cosine >= threshold)
      .length;
  final vf = v
      .where((p) => p.judgment == 'different' && p.cosine >= threshold)
      .length;
  if (vf > 0 || vp == 0) {
    return result(
      'Validation did not pass. Automatic assignment remains off.',
      ct: bestTrue,
      vt: vp,
      vf: vf,
    );
  }
  return result(
    'Passed this reviewed sample; not a general accuracy guarantee.',
    threshold: best,
    ct: bestTrue,
    vt: vp,
  );
}
