import '../../domain/search/search_backend.dart';
import '../../models/photo.dart';
import '../search_engine.dart';

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
      searchPhotos(corpus, query);
}
