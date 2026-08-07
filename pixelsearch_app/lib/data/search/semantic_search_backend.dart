import '../../ai/ai_logger.dart';
import '../../ai/text_embedder.dart';
import '../../domain/search/hybrid_scorer.dart';
import '../../domain/search/search_backend.dart';
import '../../domain/search/vector_index.dart';
import '../../models/photo.dart';
import '../search_engine.dart'; // keywordScore + queryTerms (re-exported)

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
class SemanticSearchBackend implements SearchBackend {
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

  /// Neighbors below this cosine are treated as non-matches and excluded from
  /// the semantic candidate set (precision guard). Default 0.15 is a
  /// **recall-favoring** floor grounded in measurement: on the 6-image parity
  /// set the minimum correct-pair cosine was 0.198 and the maximum distractor
  /// 0.146 (see BENCHMARK_RESULTS.md §M6), so 0.15 keeps every observed correct
  /// match while dropping obvious non-matches. Principled threshold selection on
  /// a larger labeled set is deferred to the M14 evaluation — not fabricated.
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
    if (query.trim().isEmpty) {
      return [...corpus]..sort((a, b) => b.date.compareTo(a.date)); // browse
    }

    final terms = queryTerms(query);
    final byId = {for (final p in corpus) p.id: p};

    // Lexical signal for every photo (also the sole signal when degraded/empty).
    final lexById = <String, double>{
      for (final p in corpus) p.id: keywordScore(p, terms),
    };

    // Semantic signal (best-effort).
    final cosById = <String, double>{};
    if (!_degraded && index.length > 0) {
      try {
        if (!embedder.isLoaded) await embedder.load();
        final qvec = await embedder.embed(query);
        for (final m in index.query(qvec, topK: topK)) {
          if (m.score >= semanticMinCosine) cosById[m.id] = m.score;
        }
      } catch (e, st) {
        _degraded = true;
        _log.error('semantic search unavailable — falling back to keyword', e, st);
      }
    }

    // Candidate set = semantic neighbors ∪ lexical hits (present in the corpus).
    final ids = <String>{
      ...cosById.keys,
      for (final e in lexById.entries)
        if (e.value > 0) e.key,
    };
    final candidates = <ScoredCandidate>[
      for (final id in ids)
        if (byId[id] != null)
          ScoredCandidate(
            photo: byId[id]!,
            cosine: cosById[id],
            lexicalRaw: lexById[id] ?? 0.0,
          ),
    ];

    return scorer.rank(query, candidates);
  }
}
