import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ai_contract.dart';
import '../data/search/brute_force_vector_index.dart';
import '../data/search/keyword_search_backend.dart';
import '../domain/search/search_backend.dart';
import '../domain/search/search_response.dart';
import '../domain/search/vector_index.dart';
import '../models/photo.dart';
import 'library_providers.dart';
import 'people_providers.dart';
import 'semantic_wiring.dart';
import 'storage_providers.dart';

/// The shared similarity index (kept alive for the session; ANN-swappable —
/// ADR-009). Populated from the DB by [indexWarmupProvider].
final vectorIndexProvider = Provider<VectorIndex>(
  (ref) => BruteForceVectorIndex(dim: AiContract.embeddingDim),
);

/// Loads current-version image embeddings from the store into the index. Runs
/// once; when it completes, [searchBackendProvider] rebuilds so results refresh
/// against the populated index. Native-only (no DB on web). Returns the count.
/// The indexing controller invalidates this after a run so newly-indexed photos
/// become searchable.
final indexWarmupProvider = FutureProvider<int>((ref) async {
  final index = ref.watch(vectorIndexProvider);
  final repo = ref.watch(photoRepositoryProvider);
  final embeddings = await repo.loadEmbeddings();
  index.clear();
  embeddings.forEach(index.upsert);
  return index.length;
});

/// The active search strategy. Web → lexical (no ONNX). Native → semantic (CLIP)
/// over the text encoder provisioned at `<support>/models/…`, assembled
/// behind a conditional-import boundary ([buildSemanticBackend]) so this
/// web-reachable file never imports the AI stack. Falls back to lexical when the
/// backend can't be built. See ADR-014.
final searchBackendProvider = FutureProvider<SearchBackend>((ref) async {
  final index = ref.watch(vectorIndexProvider);
  if (!kIsWeb) {
    await ref.watch(indexWarmupProvider.future);
  }
  final semantic = await buildSemanticBackend(index); // null on web / not ready
  return semantic ?? const KeywordSearchBackend();
});

/// Ranked results for the current (debounced) query over the library. Async
/// because semantic ranking runs the text encoder; the UI renders its
/// [AsyncValue] (spinner while embedding, previous results kept).
final searchResponseProvider = FutureProvider.autoDispose<SearchResponse>((
  ref,
) async {
  final corpus = ref.watch(photoLibraryProvider);
  final resolved = await ref.watch(peopleQueryProvider.future);
  if (resolved.needsChoice) {
    return SearchResponse(
      request: SearchRequest(resolved.query, filters: resolved.filters),
      photos: const [],
      mode: 'choose person',
    );
  }
  final ids = resolved.filters.personIds;
  final eligible = ids.isEmpty
      ? null
      : await ref.read(peopleRepositoryProvider).photoIdsFor(ids);
  final request = SearchRequest(
    resolved.query,
    filters: resolved.filters,
    eligiblePhotoIds: eligible,
  );
  SearchResponse response;
  if (ids.isNotEmpty && resolved.query.trim().isEmpty) {
    response = await const KeywordSearchBackend().searchDetailed(
      request,
      corpus,
    );
  } else {
    final backend = await ref.watch(searchBackendProvider.future);
    response = await backend.searchDetailed(request, corpus);
  }
  if (ids.isEmpty) return response;
  final snapshot = await ref.read(peopleRepositoryProvider).load();
  return SearchResponse(
    request: request,
    photos: response.photos,
    mode: resolved.query.isEmpty ? 'people' : response.mode,
    explanations: {
      for (final photo in response.photos)
        photo.id: {
          ...?response.explanations[photo.id],
          'people': [
            for (final face in snapshot.faces)
              if (face.photoId == photo.id && ids.contains(face.personId))
                {
                  'person_id': face.personId,
                  'name': snapshot.people
                      .where((p) => p.record.id == face.personId)
                      .firstOrNull
                      ?.label,
                  'assignment': face.assignment,
                },
          ],
        },
    },
  );
});

final searchResultsProvider = FutureProvider.autoDispose<List<Photo>>(
  (ref) async => (await ref.watch(searchResponseProvider.future)).photos,
);
