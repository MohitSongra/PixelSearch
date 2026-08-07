import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';

// Native builds the real CLIP semantic backend (pulls in onnxruntime + dart:io);
// web gets the stub that returns null. This conditional import is what keeps the
// web build compiling — providers.dart never imports the AI stack directly.
import 'semantic_wiring_stub.dart'
    if (dart.library.io) 'semantic_wiring_io.dart' as impl;

/// Builds the on-device semantic [SearchBackend] over [index], or returns null
/// when the platform can't support it (web) or the model isn't provisioned yet.
/// Callers fall back to keyword search. See ADR-014.
Future<SearchBackend?> buildSemanticBackend(VectorIndex index) =>
    impl.buildSemanticBackend(index);
