import '../../models/photo.dart';
import 'query_terms.dart';

/// One search candidate handed to the [HybridScorer]: a photo plus its raw
/// signals for the current query. [cosine] is the CLIP text↔image similarity
/// (also null when top-K selection or the gate excluded its stored embedding);
/// [lexicalRaw] is the [keywordScore] over tags/labels/caption/place/album.
class ScoredCandidate {
  const ScoredCandidate({
    required this.photo,
    required this.cosine,
    required this.lexicalRaw,
  });

  final Photo photo;
  final double? cosine;
  final double lexicalRaw;
}

/// A ranked result with its component breakdown — useful for tests, telemetry
/// and a future "why this matched" affordance in the viewer.
class RankedPhoto {
  const RankedPhoto({
    required this.photo,
    required this.score,
    required this.semantic,
    required this.lexical,
    required this.face,
  });

  final Photo photo;
  final double score;
  final double semantic; // normalized semantic component ∈ [0,1]
  final double lexical; // normalized lexical component ∈ [0,1]
  final double face; // face-intent component ∈ [0,1]

  /// The dominant signal behind this result (for UI/diagnostics).
  String get reason {
    if (semantic >= lexical && semantic > 0) return 'semantic';
    if (lexical > 0) return 'keyword';
    if (face > 0) return 'people';
    return 'browse';
  }
}

/// Relative weights of the three ranking signals. Defaults put CLIP semantics
/// first, with lexical (tags/labels) as a supporting boost and a small
/// people/portrait nudge. Tunable for evaluation (M14) — recorded, never
/// fabricated. See RESEARCH_LOG.md §M6 and ADR-014.
class HybridWeights {
  const HybridWeights({
    this.semantic = 0.70,
    this.lexical = 0.25,
    this.face = 0.05,
  });

  final double semantic;
  final double lexical;
  final double face;
}

/// Fuses per-photo signals into one ranked list (Clean-Architecture *policy*:
/// pure, deterministic, no ONNX/DB/IO — fully unit-testable).
///
/// ## Method
/// * **Semantic** — the CLIP cosine is mapped to `[0,1]` against a *fixed*
///   reference band `[kSemanticFloor, kSemanticCeil]` (absolute strength, so a
///   genuinely strong match scores high even when it is the only candidate).
/// * **Lexical** — the keyword score is divided by the maximum candidate score
///   (zero-anchored max scaling, not observed min-max normalization).
/// * **Face intent** — only when the query asks for people/portraits, scaled by
///   the detected face count (saturating at [kFaceSaturation]).
///
/// `final = wSem·semantic + wLex·lexical + wFace·face`, sorted descending, ties
/// broken by recency then id (stable, reproducible ordering).
class HybridScorer {
  const HybridScorer({this.weights = const HybridWeights()});

  final HybridWeights weights;

  /// Reference band for turning a CLIP cosine into a `[0,1]` strength.
  /// Clamping at the ceiling collapses higher cosines to ties. Neither this band
  /// nor its interaction with lexical/face boosts is calibrated on scene queries.
  static const double kSemanticFloor = 0.0;
  static const double kSemanticCeil = 0.35;

  /// Face-count at which the people/portrait boost saturates.
  static const int kFaceSaturation = 3;

  /// Query tokens that express "I'm looking for people".
  static const Set<String> _faceIntentTerms = {
    'people',
    'person',
    'portrait',
    'selfie',
    'selfies',
    'group',
    'face',
    'faces',
    'crowd',
    'family',
    'friends',
    'wedding',
    'team',
    'us',
    'everyone',
  };

  /// Rank [candidates] for [query], returning photos best-first. Candidates with
  /// no signal at all (no semantic strength, no lexical hit, no face boost) are
  /// dropped. A nonzero signal is not proof of relevance.
  List<Photo> rank(String query, List<ScoredCandidate> candidates) =>
      rankDetailed(query, candidates).map((r) => r.photo).toList();

  /// As [rank], but keeps the score breakdown for each surviving candidate.
  List<RankedPhoto> rankDetailed(
    String query,
    List<ScoredCandidate> candidates,
  ) {
    if (candidates.isEmpty) return const [];

    final terms = queryTerms(query);
    final wantsFaces = terms.any(_faceIntentTerms.contains);

    // Lexical maximum reference (zero-anchored relative normalization).
    var maxLex = 0.0;
    for (final c in candidates) {
      if (c.lexicalRaw > maxLex) maxLex = c.lexicalRaw;
    }

    final ranked = <RankedPhoto>[];
    for (final c in candidates) {
      final semantic = c.cosine == null ? 0.0 : _semanticStrength(c.cosine!);
      final lexical = maxLex == 0.0
          ? 0.0
          : (c.lexicalRaw / maxLex).clamp(0.0, 1.0);
      final face = (wantsFaces && c.photo.faceCount > 0)
          ? (c.photo.faceCount.clamp(0, kFaceSaturation) / kFaceSaturation)
          : 0.0;

      final score =
          weights.semantic * semantic +
          weights.lexical * lexical +
          weights.face * face;

      if (score <= 0.0) continue; // no signal → not a result
      ranked.add(
        RankedPhoto(
          photo: c.photo,
          score: score,
          semantic: semantic,
          lexical: lexical,
          face: face,
        ),
      );
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byDate = b.photo.date.compareTo(a.photo.date); // newer first
      if (byDate != 0) return byDate;
      return a.photo.id.compareTo(b.photo.id); // stable tie-break
    });
    return ranked;
  }

  double _semanticStrength(double cosine) {
    final t = (cosine - kSemanticFloor) / (kSemanticCeil - kSemanticFloor);
    return t.clamp(0.0, 1.0);
  }
}
