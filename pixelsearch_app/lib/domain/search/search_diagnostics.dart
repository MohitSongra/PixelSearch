import '../../models/photo.dart';
import 'hybrid_scorer.dart';
import 'vector_index.dart';

/// Platform-neutral interface for the optional diagnostics UI.
abstract interface class SearchInspector {
  Future<SearchTrace> inspect(String query, List<Photo> corpus);
}

class DiagnosticRanking {
  const DiagnosticRanking(this.name, this.photos, this.rows, this.details);
  final String name;
  final List<Photo> photos;
  final List<Map<String, Object?>> rows;
  final Map<String, Object?> details;
  Map<String, Object?> toJson() => {
    ...details,
    'ranking': rows.take(200).toList(),
    'result_count': photos.length,
    'export_limit': 200,
  };
}

class SearchTrace {
  const SearchTrace({
    required this.query,
    required this.raw,
    required this.rankings,
    required this.metadata,
  });
  final String query;
  final List<VectorMatch> raw;
  final List<DiagnosticRanking> rankings;
  final Map<String, Object?> metadata;
  Map<String, Object?> toJson() => {
    'query': query,
    ...metadata,
    'rankings': {
      for (final ranking in rankings) ranking.name: ranking.toJson(),
    },
  };
}

Map<String, double> weightedContributions(RankedPhoto hit, HybridWeights w) => {
  'semantic': w.semantic * hit.semantic,
  'lexical': w.lexical * hit.lexical,
  'face': w.face * hit.face,
};
