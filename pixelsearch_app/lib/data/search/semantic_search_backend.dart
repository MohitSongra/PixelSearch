import 'dart:math' as math;

import '../../ai/ai_logger.dart';
import '../../ai/text_embedder.dart';
import '../../core/ai_contract.dart';
import '../../domain/search/hybrid_scorer.dart';
import '../../domain/search/search_backend.dart';
import '../../domain/search/search_response.dart';
import '../../domain/search/search_diagnostics.dart';
import '../../domain/search/vector_index.dart';
import '../../models/photo.dart';
import 'search_ranking.dart';

/// M6 semantic search: query text → CLIP text embedding → cosine over the
/// stored image embeddings ([VectorIndex]) → hybrid re-rank ([HybridScorer]).
///
/// Collaborators are injected (testable in isolation with fakes):
/// * [embedder] — the ONNX text encoder (loaded lazily on first query).
/// * [index]    — the similarity index, pre-populated from the DB (see
///   `indexWarmupProvider`). Empty ⇒ pure-lexical results, which is exactly the
///   right behavior on web or before the library has been indexed.
/// * [scorer]   — the pure fusion policy.
///
/// **Graceful degradation:** if the text model cannot be loaded or an embed
/// throws (model not provisioned, unsupported EP, …) the backend latches into a
/// keyword-only mode for the rest of the session instead of failing the search.
/// See ADR-014.
class SemanticSearchBackend implements SearchBackend, SearchInspector {
  SemanticSearchBackend({
    required this.embedder,
    required this.index,
    this.scorer = const HybridScorer(),
    this.topK = 60,
    this.semanticMinCosine = 0.15,
    AiLog? log,
  }) : _log = log ?? const AiLog('SemanticSearch');

  final TextEmbedder embedder;
  final VectorIndex index;
  final HybridScorer scorer;

  /// Number of nearest neighbors pulled from the index per query.
  final int topK;

  /// Applied to raw cosine after top-K selection. Historical 0.15 came from
  /// six parity probes (minimum correct 0.198, maximum distractor 0.146), not
  /// a labelled scene-retrieval dataset. Diagnostics replay a gate sweep; the
  /// production value remains unchanged pending relevance-based calibration.
  final double semanticMinCosine;

  final AiLog _log;

  /// Latches true if the model is unavailable/failed — keyword-only thereafter.
  bool _degraded = false;

  @override
  String get name => _degraded ? 'semantic(keyword-fallback)' : 'semantic';

  /// True while real embedding search is active (flips to false after a failed
  /// load/embed). The UI uses this for its "CLIP semantic" vs "keyword" badge.
  @override
  bool get isSemantic => !_degraded;

  @override
  Future<List<Photo>> search(String query, List<Photo> corpus) async {
    return (await searchDetailed(SearchRequest(query), corpus)).photos;
  }

  @override
  Future<SearchResponse> searchDetailed(
    SearchRequest request,
    List<Photo> corpus,
  ) async {
    final query = request.query;
    corpus = request.filterCorpus(corpus);
    if (query.trim().isEmpty) {
      return SearchResponse(
        request: request,
        photos: [...corpus]..sort((a, b) => b.date.compareTo(a.date)),
        mode: 'browse',
      );
    }

    // Semantic signal (best-effort).
    var matches = <VectorMatch>[];
    if (!_degraded && index.length > 0) {
      try {
        if (!embedder.isLoaded) await embedder.load();
        final qvec = await embedder.embed(query);
        matches = index.query(
          qvec,
          topK: topK,
          eligibleIds: !request.constrained
              ? null
              : corpus.map((p) => p.id).toSet(),
        );
      } catch (e, st) {
        _degraded = true;
        _log.error(
          'semantic search unavailable — falling back to keyword',
          e,
          st,
        );
      }
    }

    final run = rankSearchCandidates(
      query,
      corpus,
      matches,
      policy: RankingPolicy(
        'production',
        topK: topK,
        minCosine: semanticMinCosine,
        // ML Kit remains available to keyword-only fallback. While semantic
        // retrieval is healthy, its labels cannot override cross-modal rank.
        includeMlKitLabels: _degraded || index.length == 0,
        allowLexicalOnly: _degraded || index.length == 0,
        ignoreArticles: !_degraded && index.length > 0,
      ),
      scorer: scorer,
    );
    final candidates = {for (final c in run.candidates) c.photo.id: c};
    final raw = {for (final m in matches) m.id: m.score};
    final terms = lexicalTermsForPolicy(query, run.policy);
    return SearchResponse(
      request: request,
      photos: run.ranked.map((r) => r.photo).toList(),
      mode: _degraded || index.length == 0 ? 'keyword fallback' : 'semantic',
      explanations: {
        for (final r in run.ranked)
          r.photo.id: {
            'cosine': raw[r.photo.id],
            'cosine_used': candidates[r.photo.id]!.cosine,
            'semantic': r.semantic,
            'lexical': r.lexical,
            'face': r.face,
            'score': r.score,
            'weighted': weightedContributions(r, scorer.weights),
            'matching_terms': terms
                .where(
                  (t) => lexicalScoreForPolicy(r.photo, [t], run.policy) > 0,
                )
                .toList(),
            'mlkit_labels_used': run.policy.includeMlKitLabels,
            'matched_metadata': matchedSearchMetadata(
              r.photo,
              terms,
              includeLabels: run.policy.includeMlKitLabels,
            ),
            'gate': semanticMinCosine,
            'pool': topK,
          },
      },
    );
  }

  /// Strict diagnostic path: one embedding and one ungated full cosine scan.
  /// Failure is surfaced, never relabelled as a successful semantic evaluation.
  @override
  Future<SearchTrace> inspect(String query, List<Photo> corpus) async {
    if (query.trim().isEmpty) throw ArgumentError('Enter a non-empty query.');
    if (index.length == 0) {
      throw StateError('No indexed embeddings to evaluate.');
    }
    if (_degraded) {
      throw StateError(
        'Normal search is latched in keyword fallback. Restart the app after resolving the model error before evaluating.',
      );
    }
    final loadedBefore = embedder.isLoaded;
    final embedWatch = Stopwatch()..start();
    if (!embedder.isLoaded) await embedder.load();
    final vector = await embedder.embed(query);
    embedWatch.stop();
    final norm = math.sqrt(vector.fold<double>(0, (n, v) => n + v * v));
    if (vector.length != AiContract.embeddingDim ||
        !norm.isFinite ||
        (norm - 1).abs() > 0.001) {
      throw StateError('Query embedding is not finite/unit-normalized: $norm');
    }
    final scanWatch = Stopwatch()..start();
    final matches = index.query(vector, topK: index.length);
    scanWatch.stop();
    if (matches.any((m) => !m.score.isFinite)) {
      throw StateError('The index contains non-finite similarities.');
    }
    final byId = {for (final p in corpus) p.id: p};
    final raw = matches.where((m) => byId.containsKey(m.id)).toList();
    final rawPositions = {
      for (var i = 0; i < raw.length; i++) raw[i].id: i + 1,
    };
    final rawCosines = {for (final m in raw) m.id: m.score};
    final rankings = <DiagnosticRanking>[
      DiagnosticRanking(
        'raw_semantic',
        [for (final m in raw) byId[m.id]!],
        [
          for (var i = 0; i < math.min(200, raw.length); i++)
            {
              'rank': i + 1,
              'id': raw[i].id,
              'filename': byId[raw[i].id]!.assetName,
              'cosine': raw[i].score,
              'raw_rank': i + 1,
            },
        ],
        {
          'policy': 'cosine only, no gate, no hybrid',
          'elapsed_ms': scanWatch.elapsedMicroseconds / 1000,
        },
      ),
    ];
    final policies = [
      RankingPolicy(
        'production',
        topK: topK,
        minCosine: semanticMinCosine,
        includeMlKitLabels: false,
        ignoreArticles: true,
      ),
      RankingPolicy(
        'legacy_articles_experiment',
        topK: topK,
        minCosine: semanticMinCosine,
      ),
      RankingPolicy(
        'legacy_mlkit_labels_experiment',
        topK: topK,
        minCosine: semanticMinCosine,
        includeMlKitLabels: true,
        allowLexicalOnly: true,
      ),
      RankingPolicy(
        'lexical_bypass_experiment',
        topK: topK,
        minCosine: semanticMinCosine,
        allowLexicalOnly: true,
        ignoreArticles: true,
      ),
      RankingPolicy(
        'whole_words_experiment',
        topK: topK,
        minCosine: semanticMinCosine,
        wholeWords: true,
        includeMlKitLabels: false,
        ignoreArticles: true,
      ),
      for (final k in [20, 50, 100, 200])
        RankingPolicy(
          'pool_$k',
          topK: k,
          minCosine: semanticMinCosine,
          ignoreArticles: true,
        ),
      for (final gate in <double?>[null, 0.0, 0.1, 0.2, 0.25, 0.3])
        RankingPolicy(
          'gate_${gate ?? 'disabled'}',
          topK: topK,
          minCosine: gate,
          ignoreArticles: true,
        ),
    ];
    for (final policy in policies) {
      final terms = lexicalTermsForPolicy(query, policy);
      final run = rankSearchCandidates(
        query,
        corpus,
        matches,
        policy: policy,
        scorer: scorer,
      );
      final candidates = {for (final c in run.candidates) c.photo.id: c};
      rankings.add(
        DiagnosticRanking(
          policy.name,
          run.ranked.map((r) => r.photo).toList(),
          [
            for (var i = 0; i < math.min(200, run.ranked.length); i++)
              {
                'rank': i + 1,
                'id': run.ranked[i].photo.id,
                'filename': run.ranked[i].photo.assetName,
                'raw_rank': rawPositions[run.ranked[i].photo.id],
                'cosine': rawCosines[run.ranked[i].photo.id],
                'cosine_used': candidates[run.ranked[i].photo.id]!.cosine,
                'semantic_candidate': run.semanticIds.contains(
                  run.ranked[i].photo.id,
                ),
                'lexical_raw': candidates[run.ranked[i].photo.id]!.lexicalRaw,
                'lexical_term_scores': {
                  for (final term in terms.toSet())
                    term: lexicalScoreForPolicy(run.ranked[i].photo, [
                      term,
                    ], policy),
                },
                'semantic': run.ranked[i].semantic,
                'lexical': run.ranked[i].lexical,
                'face': run.ranked[i].face,
                'score': run.ranked[i].score,
                'weighted': weightedContributions(
                  run.ranked[i],
                  scorer.weights,
                ),
              },
          ],
          {
            'policy': policy.toJson(),
            'elapsed_ms': run.elapsedMs,
            'semantic_candidate_ids': run.semanticIds
                .where(byId.containsKey)
                .toList(),
            'candidate_count': run.candidates.length,
            'lexical_only_count': run.candidates
                .where((c) => c.cosine == null)
                .length,
            'semantic_saturated_count': run.ranked
                .where((r) => r.semantic == 1)
                .length,
          },
        ),
      );
    }
    final native = embedder is OnnxTextEmbedder
        ? embedder as OnnxTextEmbedder
        : null;
    return SearchTrace(
      query: query,
      raw: raw,
      rankings: rankings,
      metadata: {
        'status': '[VERIFIED] measured ranking; relevance unjudged',
        'corpus_count': corpus.length,
        'index_count': index.length,
        'missing_embedding_ids': byId.keys
            .where((id) => !rawCosines.containsKey(id))
            .toList(),
        'orphan_embedding_ids': matches
            .where((m) => !byId.containsKey(m.id))
            .map((m) => m.id)
            .toList(),
        'model_path': native?.modelPath,
        'query_embedding': vector.toList(),
        'query_norm': norm,
        'query_dimensions': vector.length,
        'token_ids': native?.tokenizer.tokenize(query).toList(),
        'truncated': native == null
            ? null
            : native.tokenizer.encode(query).length + 2 >
                  native.tokenizer.contextLength,
        'embedding_ms_including_load_if_cold':
            embedWatch.elapsedMicroseconds / 1000,
        'model_was_loaded': loadedBefore,
        'full_cosine_scan_ms': scanWatch.elapsedMicroseconds / 1000,
        'weights': {
          'semantic': scorer.weights.semantic,
          'lexical': scorer.weights.lexical,
          'face': scorer.weights.face,
        },
        'semantic_band': [
          HybridScorer.kSemanticFloor,
          HybridScorer.kSemanticCeil,
        ],
        'lexical_policy_changed_in_production': true,
      },
    );
  }
}
