import '../../models/photo.dart';
import 'search_response.dart';

/// Strategy for turning a text query + a photo corpus into ranked results.
///
/// Two implementations swap behind this one interface (ADR-009):
/// [KeywordSearchBackend] (lexical, sync-under-the-hood, also the web fallback)
/// and [SemanticSearchBackend] (M6: query text → CLIP embedding → [VectorIndex]
/// cosine → hybrid re-rank). The search provider and UI depend only on this
/// contract.
///
/// [search] is asynchronous because semantic ranking must run a text encoder
/// (ONNX Runtime) off the caller's stack; the keyword backend simply returns an
/// already-complete future. See ADR-014.
abstract interface class SearchBackend {
  /// Short identifier for diagnostics and benchmarks.
  String get name;

  /// Whether this backend performs true semantic (embedding) search.
  bool get isSemantic;

  /// Rank [corpus] against [query]. An empty query returns the corpus
  /// newest-first (the browse state).
  Future<List<Photo>> search(String query, List<Photo> corpus);
  Future<SearchResponse> searchDetailed(
    SearchRequest request,
    List<Photo> corpus,
  );
}
