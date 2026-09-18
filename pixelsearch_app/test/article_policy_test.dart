import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/search/search_ranking.dart';
import 'package:pixelsearch/domain/search/vector_index.dart';
import 'package:pixelsearch/models/photo.dart';

void main() {
  const policy = RankingPolicy('articles', ignoreArticles: true);
  Photo photo(String id, String album) => Photo(
    id: id,
    title: '',
    caption: '',
    tags: [],
    date: DateTime(2026),
    album: album,
    source: PhotoSource.sample,
  );

  test(
    'only articles are omitted; relation, quantity and negation terms remain',
    () {
      expect(
        lexicalTermsForPolicy(
          'a child beside the car with an umbrella',
          policy,
        ),
        ['child', 'beside', 'car', 'with', 'umbrella'],
      );
      expect(lexicalTermsForPolicy('two people not inside', policy), [
        'two',
        'people',
        'not',
        'inside',
      ]);
      expect(lexicalTermsForPolicy('A AN THE', policy), isEmpty);
    },
  );
  test('article-only metadata cannot override a higher cosine', () {
    final corpus = [
      photo('higher', 'Trips'),
      photo('lower', 'WhatsApp Images'),
    ];
    final matches = [
      const VectorMatch('higher', .2),
      const VectorMatch('lower', .19),
    ];
    final legacy = rankSearchCandidates(
      'a dog',
      corpus,
      matches,
      policy: const RankingPolicy('legacy'),
    );
    final current = rankSearchCandidates(
      'a dog',
      corpus,
      matches,
      policy: policy,
    );
    expect(legacy.ranked.first.photo.id, 'lower');
    expect(current.ranked.first.photo.id, 'higher');
    expect(current.ranked.every((r) => r.lexical == 0), isTrue);
    expect(current.semanticIds, legacy.semanticIds);
  });
  test('content-word metadata and explicit legacy replay remain available', () {
    final p = photo('p', 'Dog photos');
    expect(lexicalScoreForPolicy(p, ['dog'], policy), greaterThan(0));
    expect(lexicalScoreForPolicy(photo('q', 'WhatsApp'), ['a'], policy), 0);
    expect(
      lexicalScoreForPolicy(photo('q', 'WhatsApp'), [
        'a',
      ], const RankingPolicy('legacy')),
      greaterThan(0),
    );
  });
}
