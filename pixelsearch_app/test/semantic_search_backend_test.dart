import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/ai/text_embedder.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/domain/search/search_response.dart';

Float32List _unit(List<double> xs) {
  var n = 0.0;
  for (final x in xs) {
    n += x * x;
  }
  n = math.sqrt(n);
  return Float32List.fromList([for (final x in xs) n == 0 ? 0.0 : x / n]);
}

/// Deterministic text encoder: maps known queries to fixed vectors. Optionally
/// fails to load, to exercise the graceful keyword fallback.
class _FakeTextEmbedder implements TextEmbedder {
  _FakeTextEmbedder(this._table, {this.failLoad = false});
  final Map<String, List<double>> _table;
  final bool failLoad;
  bool _loaded = false;
  int embedCalls = 0;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async {
    if (failLoad) throw Exception('model not provisioned');
    _loaded = true;
  }

  @override
  Future<Float32List> embed(String text) async {
    embedCalls++;
    return _unit(_table[text.toLowerCase()] ?? const [0, 0, 0]);
  }

  @override
  Future<void> dispose() async => _loaded = false;
}

Photo _photo(
  String id, {
  List<String> tags = const [],
  List<String> labels = const [],
  DateTime? date,
}) => Photo(
  id: id,
  title: id,
  caption: '',
  tags: tags,
  labels: labels,
  date: date ?? DateTime(2026, 1, 1),
  album: 'A',
  source: PhotoSource.sample,
);

void main() {
  test('person eligibility filters before global Top-K and name-only needs no encoder', () async {
    final encoder = _FakeTextEmbedder({'beach': [1, 0, 0]}, failLoad: true);
    final index = BruteForceVectorIndex(dim: 3)
      ..upsert('other', _unit([1, 0, 0]))..upsert('person', _unit([.8, .6, 0]));
    final corpus = [_photo('other'), _photo('person')];
    final offline = SemanticSearchBackend(embedder: encoder, index: index, topK: 1);
    final named = await offline.searchDetailed(const SearchRequest('',
      filters: SearchFilters(personIds: {'local-person'}), eligiblePhotoIds: {'person'}), corpus);
    expect(named.photos.map((p) => p.id), ['person']);
    expect(encoder.embedCalls, 0);
    expect(encoder.isLoaded, isFalse);
    final backend = SemanticSearchBackend(embedder: _FakeTextEmbedder({'beach': [1, 0, 0]}), index: index, topK: 1);
    final scoped = await backend.searchDetailed(const SearchRequest('beach',
      filters: SearchFilters(personIds: {'local-person'}), eligiblePhotoIds: {'person'}), corpus);
    expect(scoped.photos.single.id, 'person');
    expect(scoped.explanations['person']!['cosine'], closeTo(.8, 1e-6));
    await expectLater(backend.searchDetailed(const SearchRequest('beach',
      filters: SearchFilters(personIds: {'unresolved'})), corpus), throwsStateError);
    expect((await backend.searchDetailed(const SearchRequest('beach', eligiblePhotoIds: {}), corpus)).photos, isEmpty);
  });
  test(
    'articles add no semantic-hybrid evidence and the full sentence reaches the encoder',
    () async {
      final embedder = _FakeTextEmbedder({
        'a dog': [1, 0, 0],
      });
      final index = BruteForceVectorIndex(dim: 3)
        ..upsert('photo', _unit([0.2, math.sqrt(0.96), 0]));
      final backend = SemanticSearchBackend(embedder: embedder, index: index);
      final result = await backend.searchDetailed(
        const SearchRequest('a dog'),
        [_photo('photo')],
      );
      expect(result.photos.single.id, 'photo');
      final evidence = result.explanations['photo']!;
      expect(evidence['cosine'], closeTo(0.2, 1e-6));
      expect(evidence['lexical'], 0);
      expect(evidence['matching_terms'], isEmpty);
      expect(evidence['matched_metadata'], isEmpty);
      expect((evidence['weighted'] as Map)['lexical'], 0);
      expect(embedder.embedCalls, 1);
    },
  );

  test(
    'detailed response uses one embedding and reproduces final score',
    () async {
      final embedder = _FakeTextEmbedder({
        'scene': [1, 0, 0],
      });
      final index = BruteForceVectorIndex(dim: 3)
        ..upsert('a', _unit([1, 0, 0]));
      final backend = SemanticSearchBackend(embedder: embedder, index: index);
      final response = await backend.searchDetailed(
        const SearchRequest('scene'),
        [_photo('a')],
      );
      expect(embedder.embedCalls, 1);
      final explanation = response.explanations['a']!;
      final weighted = explanation['weighted'] as Map<String, double>;
      expect(
        weighted.values.fold<double>(0, (a, b) => a + b),
        explanation['score'],
      );
      expect(explanation['cosine'], closeTo(1, 1e-6));
      expect(explanation['mlkit_labels_used'], isFalse);
    },
  );
  test('date restriction is applied before Top-K', () async {
    final index = BruteForceVectorIndex(dim: 3)
      ..upsert('outside', _unit([1, 0, 0]))
      ..upsert('inside', _unit([0.8, 0.6, 0]));
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder({
        'scene': [1, 0, 0],
      }),
      index: index,
      topK: 1,
    );
    final result = await backend.searchDetailed(
      SearchRequest('scene', filters: SearchFilters(from: DateTime(2026))),
      [_photo('outside', date: DateTime(2025)), _photo('inside')],
    );
    expect(result.photos.single.id, 'inside');
  });
  // A tiny 3-D "embedding space": beach, dog, city on orthogonal axes.
  final corpus = [
    _photo('beach', tags: ['beach', 'sea']),
    _photo('dog', tags: ['dog', 'pet']),
    _photo('city', tags: ['city', 'skyline']),
  ];

  BruteForceVectorIndex populatedIndex() => BruteForceVectorIndex(dim: 3)
    ..upsert('beach', _unit([1, 0, 0]))
    ..upsert('dog', _unit([0, 1, 0]))
    ..upsert('city', _unit([0, 0, 1]));

  final table = {
    'beach': [1.0, 0.0, 0.0],
    'dog': [0.0, 1.0, 0.0],
  };

  test('semantic query retrieves the nearest photo first', () async {
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder(table),
      index: populatedIndex(),
    );
    final results = await backend.search('dog', corpus);
    expect(results.first.id, 'dog');
    expect(backend.isSemantic, isTrue);
  });

  test(
    'semantic beats lexical: a query with no keyword match still ranks by CLIP',
    () async {
      // Query "puppy" isn't a tag on any photo, but the fake maps it near the dog axis.
      final backend = SemanticSearchBackend(
        embedder: _FakeTextEmbedder({
          'puppy': [0.1, 0.99, 0.0],
        }),
        index: populatedIndex(),
      );
      final results = await backend.search('puppy', corpus);
      expect(results.first.id, 'dog'); // found with zero lexical overlap
    },
  );

  test('empty query returns the corpus newest-first (browse)', () async {
    final dated = [
      _photo('old', date: DateTime(2025, 1, 1)),
      _photo('new', date: DateTime(2026, 1, 1)),
    ];
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder(table),
      index: populatedIndex(),
    );
    final results = await backend.search('   ', dated);
    expect(results.map((p) => p.id).toList(), ['new', 'old']);
  });

  test('weak neighbors below semanticMinCosine are excluded', () async {
    // Isolated index with a single 'beach' vector. The query sits ~0.10 cosine
    // from it (below the 0.2 floor) and has no lexical overlap, so nothing is
    // returned. (In the 3-axis index every query is strong to some axis, so this
    // needs its own single-vector fixture.)
    final idx = BruteForceVectorIndex(dim: 3)
      ..upsert('beach', _unit([1, 0, 0]));
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder({
        'faint': [0.1, 1.0, 0.0],
      }), // cos≈0.10 to beach
      index: idx,
      semanticMinCosine: 0.2,
    );
    final results = await backend.search('faint', [
      _photo('beach', tags: ['beach']),
    ]);
    expect(results, isEmpty);
  });

  test('gracefully degrades to keyword when the model fails to load', () async {
    final embedder = _FakeTextEmbedder(table, failLoad: true);
    final backend = SemanticSearchBackend(
      embedder: embedder,
      index: populatedIndex(),
    );
    final results = await backend.search('beach', corpus);
    expect(results.first.id, 'beach'); // via lexical fallback (tag match)
    expect(backend.isSemantic, isFalse); // latched into keyword mode
    expect(embedder.embedCalls, 0); // never embedded after load failed
  });

  test(
    'keyword fallback retains ML Kit labels when semantic loading fails',
    () async {
      final backend = SemanticSearchBackend(
        embedder: _FakeTextEmbedder(table, failLoad: true),
        index: populatedIndex(),
      );
      final results = await backend.search('dog', [
        _photo('labelled', labels: ['dog']),
      ]);
      expect(results.single.id, 'labelled');
      expect(backend.isSemantic, isFalse);
    },
  );

  test('empty index → pure lexical results (no crash)', () async {
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder(table),
      index: BruteForceVectorIndex(dim: 3), // nothing indexed
    );
    final results = await backend.search('city', corpus);
    expect(results.single.id, 'city'); // only the tag match
  });

  test('article and exact tags cannot bypass the semantic cutoff', () async {
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder({
        'a dog': [0, 1, 0],
      }),
      index: populatedIndex(),
    );
    final photos = [
      _photo('beach', tags: ['dog'], labels: ['dog']),
      _photo('dog'),
      _photo('city', tags: ['a dog']),
      _photo('unindexed', tags: ['dog']),
    ];
    expect((await backend.search('a dog', photos)).map((p) => p.id), ['dog']);
  });

  test(
    'no semantic matches stays empty despite album article matches',
    () async {
      final backend = SemanticSearchBackend(
        embedder: _FakeTextEmbedder({
          'a dog': [0, 0, -1],
        }),
        index: populatedIndex(),
      );
      expect(await backend.search('a dog', corpus), isEmpty);
    },
  );

  test('two semantic matches return two, without filling top K', () async {
    final backend = SemanticSearchBackend(
      embedder: _FakeTextEmbedder({
        'a dog': [1, 1, 0],
      }),
      index: populatedIndex(),
    );
    expect((await backend.search('a dog', corpus)).map((p) => p.id).toSet(), {
      'beach',
      'dog',
    });
  });
}
