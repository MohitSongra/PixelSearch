import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/evaluation/evaluation_runner.dart';
import 'package:pixelsearch/evaluation/retrieval_evaluation.dart';

import 'search_diagnostics_test.dart'
    show fixturePhoto, fixtureVector, DiagnosticFakeEmbedder;

void main() {
  test('bundled dataset contains 24 unlabelled cases in six categories', () {
    final dataset = EvaluationDataset.parse(
      File('assets/evaluation/scene_queries.json').readAsStringSync(),
    );
    expect(dataset.queries, hasLength(24));
    expect(dataset.queries.map((q) => q.category).toSet(), hasLength(6));
    expect(
      dataset.queries.every((q) => q.judgments.isEmpty && !q.exhaustive),
      isTrue,
    );
    expect(
      EvaluationDataset.parse(jsonEncode(dataset.toJson())).toJson(),
      dataset.toJson(),
    );
  });

  test(
    'missing judgments withhold quality numbers rather than returning zeros',
    () {
      final m = metricsAt(['x'], {}, 5);
      expect(m['precision_at_k'], isNull);
      expect(m['known_positive_recall_at_k'], isNull);
      expect(m['judged_pool_ndcg_at_k'], isNull);
      expect(m['unjudged_returned'], 1);
    },
  );

  test(
    'unjudged results are not negatives; known-positive recall is explicit',
    () {
      final m = metricsAt(['x', 'y'], {'x': 2, 'z': 2}, 2);
      expect(m['precision_at_k'], isNull);
      expect(m['judged_pool_ndcg_at_k'], isNull);
      expect(m['known_positive_recall_at_k'], .5);
    },
  );

  test(
    'precision uses K even when fewer results return; graded nDCG credits partial',
    () {
      final m = metricsAt(['x', 'y'], {'x': 2, 'y': 1}, 5);
      expect(m['precision_at_k'], .2);
      expect(m['judged_pool_ndcg_at_k'], 1);
      final reverse = metricsAt(['y', 'x'], {'x': 2, 'y': 1}, 2);
      expect(reverse['judged_pool_ndcg_at_k'] as double, lessThan(1));
    },
  );

  test('exhaustive is opt-in and duplicate result IDs are rejected', () {
    expect(
      metricsAt(['x', 'y'], {'x': 2}, 2, exhaustive: true)['precision_at_k'],
      .5,
    );
    expect(() => metricsAt(['x', 'x'], {'x': 2}, 2), throwsArgumentError);
  });

  test('labels resolve by exact ID or unique filename, never guessed', () {
    final corpus = [fixturePhoto('x'), fixturePhoto('y')];
    const q = EvaluationQuery(
      id: 'q',
      query: 'scene',
      judgments: {'x.jpg': 2, 'y': 0},
    );
    expect(resolveJudgments(q, corpus), {'x': 2, 'y': 0});
    expect(
      () => resolveJudgments(q, [fixturePhoto('y')]),
      throwsFormatException,
    );
    expect(
      () => resolveJudgments(q, [
        fixturePhoto('x'),
        fixturePhoto('x'),
        fixturePhoto('y'),
      ]),
      throwsFormatException,
    );
    expect(
      () => resolveJudgments(
        const EvaluationQuery(
          id: 'q',
          query: 'scene',
          judgments: {'x': 0, 'x.jpg': 2},
        ),
        corpus,
      ),
      throwsFormatException,
    );
  });

  test('dataset rejects conflicting grades and duplicate query IDs', () {
    final row = {
      'id': 'q',
      'query': 'scene',
      'relevant': ['x'],
      'irrelevant': ['x'],
    };
    String encode(List<Object> rows) => jsonEncode({
      'schema_version': 1,
      'dataset_id': 'test',
      'queries': rows,
    });
    expect(() => EvaluationDataset.parse(encode([row])), throwsFormatException);
    row['irrelevant'] = <String>[];
    expect(
      () => EvaluationDataset.parse(encode([row, row])),
      throwsFormatException,
    );
  });

  test('snapshot fingerprints are order-stable and detect vector changes', () {
    final corpus = [fixturePhoto('x'), fixturePhoto('y')];
    final vectors = {'x': fixtureVector(.3), 'y': fixtureVector(.2)};
    final a = corpusSnapshot(corpus, vectors);
    final b = corpusSnapshot(corpus.reversed.toList(), {
      'y': vectors['y']!,
      'x': vectors['x']!,
    });
    expect(a['metadata_sha256'], b['metadata_sha256']);
    expect(a['vectors_sha256'], b['vectors_sha256']);
    expect(a['invalid_vector_ids'], isEmpty);
    vectors['x'] = fixtureVector(.4);
    expect(
      corpusSnapshot(corpus, vectors)['vectors_sha256'],
      isNot(a['vectors_sha256']),
    );
  });

  test(
    'runner records real fixture traces but keeps unlabelled metrics null',
    () async {
      final corpus = [fixturePhoto('x')];
      final vectors = {'x': fixtureVector(.3)};
      final backend = SemanticSearchBackend(
        embedder: DiagnosticFakeEmbedder(),
        index: BruteForceVectorIndex()..upsert('x', vectors['x']!),
      );
      final result = await runSearchEvaluation(
        inspector: backend,
        corpus: corpus,
        vectors: vectors,
        dataset: const EvaluationDataset('fixture', [
          EvaluationQuery(id: 'q', query: 'scene'),
        ]),
      );
      expect(result['labelled_query_count'], 0);
      final query = (result['queries'] as List).single as Map;
      final evaluation = query['evaluation'] as Map;
      final systems = evaluation['systems'] as Map;
      expect(
        ((systems['production'] as Map)['metrics'] as List)
            .first['precision_at_k'],
        isNull,
      );
    },
  );
}
