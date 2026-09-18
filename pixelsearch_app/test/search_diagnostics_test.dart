import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/ai/text_embedder.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/search_ranking.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/data/search_engine.dart';
import 'package:pixelsearch/domain/search/hybrid_scorer.dart';
import 'package:pixelsearch/domain/search/vector_index.dart';
import 'package:pixelsearch/models/photo.dart';

Photo fixturePhoto(
  String id, {
  String album = '',
  List<String> labels = const [],
  List<String> tags = const [],
  int faces = 0,
}) => Photo(
  id: id,
  assetName: '$id.jpg',
  title: '',
  caption: '',
  tags: tags,
  date: DateTime(2026),
  album: album,
  source: PhotoSource.sample,
  labels: labels,
  faceCount: faces,
);

Float32List fixtureVector(double cosine) => Float32List(512)
  ..[0] = cosine
  ..[1] = math.sqrt(1 - cosine * cosine);

class DiagnosticFakeEmbedder implements TextEmbedder {
  bool fail = false;
  bool invalid = false;
  int calls = 0;
  String? lastQuery;
  @override
  bool isLoaded = false;
  @override
  Future<void> load() async {
    if (fail) throw StateError('fixture failure');
    isLoaded = true;
  }

  @override
  Future<Float32List> embed(String text) async {
    calls++;
    lastQuery = text;
    return invalid ? Float32List(512) : fixtureVector(1);
  }

  @override
  Future<void> dispose() async => isLoaded = false;
}

void main() {
  test('historical replay preserves the lexical-bypass policy', () {
    final corpus = List.generate(
      100,
      (i) => fixturePhoto(
        '$i',
        album: i.isEven ? 'Camera' : '',
        labels: i % 3 == 0 ? ['person'] : [],
        faces: i % 4,
      ),
    );
    final matches = List.generate(100, (i) => VectorMatch('$i', .5 - i / 150));
    const scorer = HybridScorer();
    for (final query in [
      'a person in a garden',
      'dog',
      'friends together',
      'on',
    ]) {
      final byId = {for (final p in corpus) p.id: p};
      final lexical = {
        for (final p in corpus)
          p.id: keywordScore(p, queryTerms(query), includeLabels: false),
      };
      final cosine = {
        for (final m in matches.take(60))
          if (m.score >= .15) m.id: m.score,
      };
      final ids = {
        ...cosine.keys,
        for (final e in lexical.entries)
          if (e.value > 0) e.key,
      };
      final old = scorer.rankDetailed(query, [
        for (final id in ids)
          ScoredCandidate(
            photo: byId[id]!,
            cosine: cosine[id],
            lexicalRaw: lexical[id] ?? 0,
          ),
      ]);
      final actual = rankSearchCandidates(
        query,
        corpus,
        matches,
        policy: const RankingPolicy(
          'lexical_bypass_experiment',
          allowLexicalOnly: true,
        ),
      );
      expect(
        actual.ranked.map((r) => (r.photo.id, r.score)),
        old.map((r) => (r.photo.id, r.score)),
      );
    }
  });

  test(
    'diagnostics use one complete query embedding and match normal search',
    () async {
      final corpus = List.generate(
        230,
        (i) => fixturePhoto('$i', album: 'Camera beach'),
      );
      final index = BruteForceVectorIndex();
      for (var i = 0; i < corpus.length; i++) {
        index.upsert('$i', fixtureVector(.34 - i / 1000));
      }
      final embedder = DiagnosticFakeEmbedder();
      final backend = SemanticSearchBackend(embedder: embedder, index: index);
      const query = 'a dog running on a beach at sunset';
      final trace = await backend.inspect(query, corpus);
      expect(embedder.calls, 1);
      expect(embedder.lastQuery, query);
      expect(trace.raw, hasLength(230));
      expect(trace.rankings.first.rows, hasLength(200));
      final production = trace.rankings.firstWhere(
        (r) => r.name == 'production',
      );
      expect(
        production.photos.map((p) => p.id),
        (await backend.search(query, corpus)).map((p) => p.id),
      );
      expect(production.details['lexical_only_count'], 0);
      expect(production.photos, hasLength(60));
      final bypass = trace.rankings.firstWhere(
        (r) => r.name == 'lexical_bypass_experiment',
      );
      expect(bypass.details['lexical_only_count'], 170);
      final dropped = bypass.rows.firstWhere((r) => r['id'] == '60');
      expect(dropped['cosine'], closeTo(.28, 1e-6));
      expect(dropped['cosine_used'], isNull);
      expect(
        trace.rankings
            .firstWhere((r) => r.name == 'pool_100')
            .details['semantic_candidate_ids'],
        hasLength(100),
      );
      expect(trace.metadata['query_dimensions'], 512);
    },
  );

  test(
    'gates remove used cosine but raw rankings retain the measurement',
    () async {
      final backend = SemanticSearchBackend(
        embedder: DiagnosticFakeEmbedder(),
        index: BruteForceVectorIndex()..upsert('x', fixtureVector(.1)),
      );
      final trace = await backend.inspect('sunset', [fixturePhoto('x')]);
      expect(trace.raw.single.score, closeTo(.1, 1e-6));
      expect(
        trace.rankings.firstWhere((r) => r.name == 'production').photos,
        isEmpty,
      );
      expect(
        trace.rankings
            .firstWhere((r) => r.name == 'gate_disabled')
            .photos
            .single
            .id,
        'x',
      );
    },
  );

  test(
    'whole-word experiment rejects accidental substrings, keeps exact labels',
    () {
      final p = fixturePhoto(
        'x',
        album: 'Camera',
        labels: ['person', 'sitting', 'dog'],
      );
      expect(keywordScore(p, ['a', 'on', 'in']), 3);
      expect(wholeWordKeywordScore(p, ['a', 'on', 'in']), 0);
      expect(wholeWordKeywordScore(p, ['dog']), 2);
      expect(
        wholeWordKeywordScore(fixturePhoto('y', tags: ['dog']), ['dog']),
        3,
      );
    },
  );

  test(
    'semantic policy excludes ML Kit labels without changing keyword fallback',
    () {
      final semantic = fixturePhoto('semantic', album: 'WhatsApp Images');
      final labelled = fixturePhoto(
        'labelled',
        album: 'WhatsApp Images',
        labels: ['dog'],
      );
      const query = 'a dog';
      const current = RankingPolicy('production');
      const legacy = RankingPolicy(
        'legacy_mlkit_labels_experiment',
        includeMlKitLabels: true,
      );
      const matches = [
        VectorMatch('semantic', .20),
        VectorMatch('labelled', .15),
      ];

      final currentRun = rankSearchCandidates(
        query,
        [semantic, labelled],
        matches,
        policy: current,
      );
      final legacyRun = rankSearchCandidates(
        query,
        [semantic, labelled],
        matches,
        policy: legacy,
      );

      expect(currentRun.ranked.map((r) => r.photo.id), [
        'semantic',
        'labelled',
      ]);
      expect(legacyRun.ranked.map((r) => r.photo.id), ['labelled', 'semantic']);
      expect(keywordScore(labelled, ['dog']), 2);
      expect(keywordScore(labelled, ['dog'], includeLabels: false), 0);
    },
  );

  test('current semantic saturation is observable without changing policy', () {
    final run = rankSearchCandidates(
      'unknown',
      [fixturePhoto('a'), fixturePhoto('z')],
      [const VectorMatch('z', .6), const VectorMatch('a', .4)],
      policy: const RankingPolicy('production'),
    );
    expect(run.ranked.map((r) => r.semantic), [1, 1]);
    expect(run.ranked.first.photo.id, 'a'); // existing ID tie-break, not cosine
  });

  test(
    'diagnostics reject invalid embeddings and never report fallback as semantic',
    () async {
      final embedder = DiagnosticFakeEmbedder()..invalid = true;
      final backend = SemanticSearchBackend(
        embedder: embedder,
        index: BruteForceVectorIndex()..upsert('x', fixtureVector(.3)),
      );
      await expectLater(
        backend.inspect('scene', [fixturePhoto('x')]),
        throwsStateError,
      );
      embedder.invalid = false;
      embedder.isLoaded = false;
      embedder.fail = true;
      await backend.search('scene', [fixturePhoto('x')]);
      expect(backend.isSemantic, isFalse);
      await expectLater(
        backend.inspect('scene', [fixturePhoto('x')]),
        throwsStateError,
      );
    },
  );
}
