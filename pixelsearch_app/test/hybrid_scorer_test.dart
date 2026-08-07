import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/domain/search/hybrid_scorer.dart';
import 'package:pixelsearch/models/photo.dart';

Photo _photo(
  String id, {
  List<String> tags = const [],
  List<String> labels = const [],
  int faceCount = 0,
  DateTime? date,
}) =>
    Photo(
      id: id,
      title: id,
      caption: '',
      tags: tags,
      labels: labels,
      faceCount: faceCount,
      date: date ?? DateTime(2026, 1, 1),
      album: 'A',
      source: PhotoSource.sample,
    );

void main() {
  const scorer = HybridScorer();

  test('semantic strength dominates a lexical-only hit', () {
    final ranked = scorer.rank('sunset', [
      ScoredCandidate(photo: _photo('sem'), cosine: 0.30, lexicalRaw: 0),
      ScoredCandidate(photo: _photo('lex'), cosine: null, lexicalRaw: 3),
    ]);
    expect(ranked.map((p) => p.id).toList(), ['sem', 'lex']);
  });

  test('lexical evidence boosts an otherwise-tied semantic match', () {
    final detailed = scorer.rankDetailed('dog park', [
      ScoredCandidate(photo: _photo('a'), cosine: 0.20, lexicalRaw: 0),
      ScoredCandidate(photo: _photo('b'), cosine: 0.20, lexicalRaw: 4),
    ]);
    expect(detailed.first.photo.id, 'b'); // same cosine, b has lexical support
    expect(detailed.first.lexical, closeTo(1.0, 1e-9)); // min-max top
    expect(detailed.last.lexical, 0.0);
  });

  test('lexical component is min-max normalized across candidates', () {
    final detailed = scorer.rankDetailed('beach', [
      ScoredCandidate(photo: _photo('hi'), cosine: null, lexicalRaw: 3),
      ScoredCandidate(photo: _photo('lo'), cosine: null, lexicalRaw: 1),
    ]);
    final hi = detailed.firstWhere((r) => r.photo.id == 'hi');
    final lo = detailed.firstWhere((r) => r.photo.id == 'lo');
    expect(hi.lexical, closeTo(1.0, 1e-9));
    expect(lo.lexical, closeTo(1 / 3, 1e-9));
    expect(detailed.map((r) => r.photo.id).toList(), ['hi', 'lo']);
  });

  test('face-intent query boosts photos with faces; ordinary query does not', () {
    final withFaces = _photo('faces', faceCount: 2, date: DateTime(2026, 1, 1));
    final noFaces = _photo('none', faceCount: 0, date: DateTime(2026, 6, 1));

    // "friends" is a people-intent term → the face photo wins despite older date.
    final peopleQuery = scorer.rank('friends', [
      ScoredCandidate(photo: withFaces, cosine: 0.20, lexicalRaw: 0),
      ScoredCandidate(photo: noFaces, cosine: 0.20, lexicalRaw: 0),
    ]);
    expect(peopleQuery.first.id, 'faces');

    // "mountain" has no people intent → tie on cosine falls back to recency.
    final plainQuery = scorer.rank('mountain', [
      ScoredCandidate(photo: withFaces, cosine: 0.20, lexicalRaw: 0),
      ScoredCandidate(photo: noFaces, cosine: 0.20, lexicalRaw: 0),
    ]);
    expect(plainQuery.first.id, 'none'); // newer wins when no face boost
  });

  test('zero-signal candidates are dropped', () {
    final ranked = scorer.rank('anything', [
      ScoredCandidate(photo: _photo('ghost'), cosine: null, lexicalRaw: 0),
      ScoredCandidate(photo: _photo('neg'), cosine: -0.1, lexicalRaw: 0), // clamps to 0
      ScoredCandidate(photo: _photo('real'), cosine: 0.25, lexicalRaw: 0),
    ]);
    expect(ranked.map((p) => p.id).toList(), ['real']);
  });

  test('empty candidate list yields no results', () {
    expect(scorer.rank('x', const []), isEmpty);
  });

  test('reason reflects the dominant signal', () {
    final semantic = scorer
        .rankDetailed('x', [ScoredCandidate(photo: _photo('s'), cosine: 0.3, lexicalRaw: 0)]).first;
    expect(semantic.reason, 'semantic');

    final keyword = scorer
        .rankDetailed('x', [ScoredCandidate(photo: _photo('k'), cosine: null, lexicalRaw: 2)]).first;
    expect(keyword.reason, 'keyword');
  });

  test('cosine is mapped to strength against the fixed reference band', () {
    final r = scorer.rankDetailed(
        'x', [ScoredCandidate(photo: _photo('c'), cosine: HybridScorer.kSemanticCeil, lexicalRaw: 0)]);
    expect(r.first.semantic, closeTo(1.0, 1e-9)); // at/above ceil → full strength
  });
}
