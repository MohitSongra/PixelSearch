import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';

/// Web (no ONNX Runtime): there is no semantic backend, so the caller uses the
/// keyword fallback.
Future<SearchBackend?> buildSemanticBackend(VectorIndex index) async => null;
