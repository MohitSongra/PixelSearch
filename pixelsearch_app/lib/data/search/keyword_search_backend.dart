import '../../domain/search/search_backend.dart';
import '../../models/photo.dart';
import '../../domain/search/search_response.dart';
import '../search_engine.dart';
import 'search_ranking.dart';

/// The lexical search strategy: keyword scoring over tags/labels/caption/place.
/// It is the on-device fallback (and the only backend on web, where there is no
/// ONNX runtime). The M6 [SemanticSearchBackend] reuses its [keywordScore] as
/// the lexical component of the hybrid blend (ADR-009, ADR-014).
class KeywordSearchBackend implements SearchBackend {
  const KeywordSearchBackend();

  @override
  String get name => 'keyword';

  @override
  bool get isSemantic => false;

  @override
  Future<List<Photo>> search(String query, List<Photo> corpus) async =>
      (await searchDetailed(SearchRequest(query), corpus)).photos;

  @override
  Future<SearchResponse> searchDetailed(
    SearchRequest request,
    List<Photo> corpus,
  ) async {
    final photos = searchPhotos(
      request.filterCorpus(corpus),
      request.query,
    );
    final terms = queryTerms(request.query);
    return SearchResponse(
      request: request,
      photos: photos,
      mode: 'keyword',
      explanations: {
        for (final p in photos)
          p.id: {
            'lexical_raw': keywordScore(p, terms),
            'matching_terms': terms
                .where((t) => keywordScore(p, [t]) > 0)
                .toList(),
            'mlkit_labels_used': true,
            'matched_metadata': matchedSearchMetadata(
              p,
              terms,
              includeLabels: true,
            ),
          },
      },
    );
  }
}
