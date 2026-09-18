// Opt-in host replay. Private inputs and results stay outside committed fixtures.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/search/search_ranking.dart';
import 'package:pixelsearch/domain/search/vector_index.dart';
import 'package:pixelsearch/evaluation/retrieval_evaluation.dart';
import 'package:pixelsearch/models/photo.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('replay articles control with frozen device vectors and saved judgments', () {
    const folder = 'local_evaluation/article_policy_20260909';
    final db = sqlite3.open(
      '$folder/app_flutter/pixelsearch.sqlite',
      mode: OpenMode.readOnly,
    );
    final old = sqlite3.open(
      'local_evaluation/device_raw_semantic_snapshot_20260908_215144/pixelsearch.sqlite',
      mode: OpenMode.readOnly,
    );
    addTearDown(db.close);
    addTearDown(old.close);
    // Saved cosine traces are reusable only if every indexed vector is identical.
    expect(
      db
          .select(
            'SELECT photo_id,model_id,embedding_version,dim,hex(vector) AS vector FROM embedding_rows ORDER BY photo_id',
          )
          .map((r) => r.values.toList())
          .toList(),
      old
          .select(
            'SELECT photo_id,model_id,embedding_version,dim,hex(vector) AS vector FROM embedding_rows ORDER BY photo_id',
          )
          .map((r) => r.values.toList())
          .toList(),
    );
    final corpus = [
      for (final row in db.select('SELECT * FROM photo_rows'))
        Photo(
          id: row['id'] as String,
          assetName: row['asset_name'] as String?,
          title: row['title'] as String,
          caption: row['caption'] as String,
          tags: (jsonDecode(row['tags_json'] as String) as List).cast<String>(),
          labels: (jsonDecode(row['labels_json'] as String) as List)
              .cast<String>(),
          date: DateTime.fromMillisecondsSinceEpoch(row['date_ms'] as int),
          place: row['place'] as String?,
          album: row['album'] as String,
          source: PhotoSource.device,
          faceCount: (jsonDecode(row['faces_json'] as String) as List).length,
        ),
    ];
    final dataset = EvaluationDataset.parse(
      File('$folder/files/search_evaluation/queries.json').readAsStringSync(),
    );
    final baseline =
        jsonDecode(
              File(
                'local_evaluation/baseline_1916_20260908_2052.json',
              ).readAsStringSync(),
            )
            as Map;
    final results = <Map<String, Object?>>[];
    for (final entry in baseline['queries'] as List) {
      final query = entry['case']['query'] as String;
      final judged = dataset.queries.singleWhere((q) => q.query == query);
      final judgments = resolveJudgments(judged, corpus);
      final raw = entry['trace']['rankings']['raw_semantic']['ranking'] as List;
      final matches = [
        for (final r in raw)
          VectorMatch(r['id'] as String, (r['cosine'] as num).toDouble()),
      ];
      expect(matches.length, greaterThanOrEqualTo(60));
      final before = rankSearchCandidates(
        query,
        corpus,
        matches,
        policy: const RankingPolicy('before_articles'),
      );
      final after = rankSearchCandidates(
        query,
        corpus,
        matches,
        policy: const RankingPolicy('ignore_articles', ignoreArticles: true),
      );
      final beforeIds = before.ranked.map((r) => r.photo.id).toList();
      final afterIds = after.ranked.map((r) => r.photo.id).toList();
      expect(after.semanticIds, before.semanticIds);
      Map<String, Object?> details(RankingRun run) => {
        'top5': metricsAt(
          run.ranked.map((r) => r.photo.id).toList(),
          judgments,
          5,
        ),
        'ranking': [
          for (final r in run.ranked)
            {'id': r.photo.id, 'score': r.score, 'lexical': r.lexical},
        ],
        'positive_ranks': {
          for (final j in judgments.entries.where((j) => j.value > 0))
            j.key: run.ranked.indexWhere((r) => r.photo.id == j.key) + 1,
        },
      };
      results.add({
        'query': query,
        'judgments': judgments.length,
        'order_changed': !orderedEquals(beforeIds).matches(afterIds, {}),
        'before': details(before),
        'after': details(after),
      });
    }
    File('$folder/replay.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'status':
            'Measured host replay of frozen Android cosine scores, current metadata, unchanged saved judgments. Not a new device inference run.',
        'corpus_count': corpus.length,
        'results': results,
      }),
    );
    // ignore: avoid_print
    print(
      'Replayed ${results.length} queries; ${results.where((r) => r['order_changed'] == true).length} changed order. Output: $folder/replay.json',
    );
  });
}
