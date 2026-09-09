import 'dart:convert';
import 'dart:math' as math;

import '../domain/search/search_diagnostics.dart';
import '../models/photo.dart';

class EvaluationQuery {
  const EvaluationQuery({
    required this.id,
    required this.query,
    this.category = 'custom',
    this.judgments = const {},
    this.exhaustive = false,
  });
  final String id;
  final String query;
  final String category;
  final Map<String, int> judgments;
  final bool exhaustive;

  EvaluationQuery judge(String photoId, int? grade) {
    final updated = {...judgments}..remove(photoId);
    if (grade != null) updated[photoId] = grade;
    return EvaluationQuery(
      id: id,
      query: query,
      category: category,
      judgments: updated,
      exhaustive: exhaustive,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'query': query,
    'category': category,
    'exhaustive': exhaustive,
    'relevant': [
      for (final e in judgments.entries)
        if (e.value == 2) e.key,
    ],
    'partially_relevant': [
      for (final e in judgments.entries)
        if (e.value == 1) e.key,
    ],
    'irrelevant': [
      for (final e in judgments.entries)
        if (e.value == 0) e.key,
    ],
  };
}

class EvaluationDataset {
  const EvaluationDataset(this.id, this.queries);
  final String id;
  final List<EvaluationQuery> queries;

  factory EvaluationDataset.parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    if (json['schema_version'] != 1) {
      throw const FormatException('Expected schema_version 1.');
    }
    final id = json['dataset_id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('dataset_id is required.');
    }
    final seen = <String>{};
    final queries = <EvaluationQuery>[];
    for (final entry in (json['queries'] as List)) {
      final row = entry as Map<String, dynamic>;
      final query = row['query'];
      final qid = row['id'];
      if (qid is! String ||
          qid.isEmpty ||
          !seen.add(qid) ||
          query is! String ||
          query.trim().isEmpty) {
        throw const FormatException(
          'Each query needs a unique id and non-empty query.',
        );
      }
      final judgments = <String, int>{};
      for (final (key, grade) in [
        ('relevant', 2),
        ('partially_relevant', 1),
        ('irrelevant', 0),
      ]) {
        for (final label in (row[key] as List? ?? const [])) {
          if (label is! String ||
              label.isEmpty ||
              judgments.containsKey(label)) {
            throw FormatException(
              '$qid: labels must be non-empty and disjoint.',
            );
          }
          judgments[label] = grade;
        }
      }
      queries.add(
        EvaluationQuery(
          id: qid,
          query: query,
          category: row['category'] as String? ?? 'custom',
          judgments: judgments,
          exhaustive: row['exhaustive'] as bool? ?? false,
        ),
      );
    }
    if (queries.isEmpty) {
      throw const FormatException('At least one query is required.');
    }
    return EvaluationDataset(id, queries);
  }

  EvaluationDataset replace(EvaluationQuery query) => EvaluationDataset(id, [
    for (final q in queries) q.id == query.id ? query : q,
    if (!queries.any((q) => q.id == query.id)) query,
  ]);
  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'dataset_id': id,
    'queries': queries.map((q) => q.toJson()).toList(),
  };
}

/// IDs are preferred; a filename is accepted only when exactly one photo has it.
/// Missing/ambiguous labels invalidate scoring rather than silently disappearing.
Map<String, int> resolveJudgments(EvaluationQuery query, List<Photo> corpus) {
  final ids = corpus.map((p) => p.id).toSet();
  final resolved = <String, int>{};
  for (final entry in query.judgments.entries) {
    final matches = ids.contains(entry.key)
        ? [entry.key]
        : corpus
              .where((p) => p.assetName == entry.key)
              .map((p) => p.id)
              .toList();
    if (matches.length != 1) {
      throw FormatException(
        '${query.id}: missing or ambiguous photo "${entry.key}". Use its asset ID.',
      );
    }
    final id = matches.single;
    if (resolved.containsKey(id) && resolved[id] != entry.value) {
      throw FormatException('${query.id}: conflicting judgments for $id.');
    }
    resolved[id] = entry.value;
  }
  return resolved;
}

Map<String, Object?> metricsAt(
  List<String> ranking,
  Map<String, int> judgments,
  int k, {
  bool exhaustive = false,
}) {
  if (k < 1) throw ArgumentError.value(k, 'k');
  if (ranking.toSet().length != ranking.length) {
    throw ArgumentError('Duplicate result IDs.');
  }
  final top = ranking.take(k).toList();
  final unjudged = top.where((id) => !judgments.containsKey(id)).length;
  final positives = judgments.entries
      .where((e) => e.value == 2)
      .map((e) => e.key)
      .toSet();
  final hits = top.where(positives.contains).length;
  final scorable = judgments.isNotEmpty && (exhaustive || unjudged == 0);
  double dcg(List<int> grades) {
    var total = 0.0;
    for (var i = 0; i < grades.length; i++) {
      total += (math.pow(2, grades[i]) - 1) / (math.log(i + 2) / math.ln2);
    }
    return total;
  }

  final ideal = judgments.values.toList()..sort((a, b) => b.compareTo(a));
  final idcg = dcg(ideal.take(k).toList());
  return {
    'k': k,
    'returned': top.length,
    'unjudged_returned': unjudged,
    'precision_at_k': scorable ? hits / k : null,
    'known_positive_recall_at_k': positives.isEmpty
        ? null
        : hits / positives.length,
    'judged_pool_ndcg_at_k': scorable && idcg > 0
        ? dcg(top.map((id) => judgments[id] ?? 0).toList()) / idcg
        : null,
    'status': judgments.isEmpty
        ? '[MISSING] relevance judgments'
        : !scorable
        ? '[PARTIAL] unjudged results; precision/nDCG withheld'
        : exhaustive
        ? '[VERIFIED] exhaustive judgments supplied by user'
        : '[PARTIAL] judged pool only; recall denominator is known positives',
  };
}

Map<String, Object?> evaluateTrace(
  SearchTrace trace,
  EvaluationQuery query,
  List<Photo> corpus,
) {
  final judgments = resolveJudgments(query, corpus);
  final positiveIds = judgments.entries
      .where((e) => e.value == 2)
      .map((e) => e.key)
      .toSet();
  final rawIds = trace.raw.map((m) => m.id).toSet();
  return {
    'query_id': query.id,
    'category': query.category,
    'judgment_count': judgments.length,
    'exhaustive': query.exhaustive,
    'positive_ids_without_embeddings': positiveIds.difference(rawIds).toList(),
    'systems': {
      for (final r in trace.rankings)
        r.name: {
          'metrics': [
            for (final k in [5, 10, 20])
              metricsAt(
                r.photos.map((p) => p.id).toList(),
                judgments,
                k,
                exhaustive: query.exhaustive,
              ),
          ],
          'known_positive_semantic_candidate_recall': positiveIds.isEmpty
              ? null
              : ((r.details['semantic_candidate_ids'] as List?)?.toSet() ??
                            rawIds)
                        .intersection(positiveIds)
                        .length /
                    positiveIds.length,
          'expected_ranks': {
            for (final id in positiveIds)
              id: r.photos.indexWhere((p) => p.id == id) < 0
                  ? null
                  : r.photos.indexWhere((p) => p.id == id) + 1,
          },
        },
    },
  };
}

/// Relevance-free observations: disagreement is not evidence of improvement.
Map<String, Object?> rankingComparison(SearchTrace trace) {
  final raw = trace.rankings.first;
  final finalRun = trace.rankings.firstWhere((r) => r.name == 'production');
  final rawTop = raw.photos.take(5).map((p) => p.id).toSet();
  final finalTop = finalRun.photos.take(5).map((p) => p.id).toSet();
  return {
    'top1_changed': raw.photos.isNotEmpty && finalRun.photos.isNotEmpty
        ? raw.photos.first.id != finalRun.photos.first.id
        : null,
    'top5_overlap_count': rawTop.intersection(finalTop).length,
    'raw_top1_final_rank': raw.photos.isEmpty
        ? null
        : finalRun.photos.indexWhere((p) => p.id == raw.photos.first.id) < 0
        ? null
        : finalRun.photos.indexWhere((p) => p.id == raw.photos.first.id) + 1,
    'quality_conclusion':
        '[MISSING] user relevance judgments; no improvement claim',
  };
}
