import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/ai/text_embedder.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/models/photo.dart';

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
