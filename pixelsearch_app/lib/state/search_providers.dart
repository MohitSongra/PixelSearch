import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ai_contract.dart';
import '../data/search/brute_force_vector_index.dart';
import '../data/search/keyword_search_backend.dart';
import '../data/search_engine.dart';
import '../domain/people/people_membership.dart';
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
  if (resolved.selfMissing || resolved.needsChoice) {
    // Never search while the subject is unknown: "me" must not reach the
    // image model, and an ambiguous name must not be guessed.
    return SearchResponse(
      request: SearchRequest(resolved.query, filters: resolved.filters),
      photos: const [],
      mode: resolved.selfMissing ? 'self missing' : 'choose person',
    );
  }
  final filters = resolved.filters;
  if (!filters.hasPeople) {
    final backend = await ref.watch(searchBackendProvider.future);
    return backend.searchDetailed(
      SearchRequest(resolved.query, filters: filters),
      corpus,
    );
  }
  final index = await ref.watch(peoplePhotoIndexProvider.future);
  final library = {for (final p in corpus) p.id};
  final required = filters.personIds, any = filters.anyPersonIds;
  // People off: every person constraint fails closed.
  final eligible = !index.enabled
      ? <String>{}
      : matchPeoplePhotos(
          index.photosByPerson,
          required: required,
          anyOf: any,
          excluded: filters.excludedPersonIds,
          universe: library,
        );
  final request = SearchRequest(
    resolved.query,
    filters: filters,
    eligiblePhotoIds: eligible,
  );
  SearchResponse response;
  if (resolved.query.trim().isEmpty) {
    // Name-only: the person's photos, newest first. No text model, and no
    // keyword evidence that did not contribute.
    response = SearchResponse(
      request: request,
      photos: searchPhotos(request.filterCorpus(corpus), ''),
      mode: 'people',
    );
  } else {
    final backend = await ref.watch(searchBackendProvider.future);
    response = await backend.searchDetailed(request, corpus);
  }
  final mentioned = {...required, ...any, ...filters.excludedPersonIds};
  final shown = {...required, ...any};
  return SearchResponse(
    request: request,
    photos: response.photos,
    mode: response.mode,
    people: PersonFilterSummary(
      peopleEnabled: index.enabled,
      labels: {
        for (final id in mentioned) id: index.labels[id] ?? 'Unnamed person',
      },
      photoCounts: {
        for (final id in mentioned)
          id: (index.photosByPerson[id] ?? const <String>{})
              .intersection(library)
              .length,
      },
      together: !index.enabled
          ? 0
          : required.isEmpty && any.isEmpty
          ? library.length
          : matchPeoplePhotos(
              index.photosByPerson,
              required: required,
              anyOf: any,
              universe: library,
            ).length,
      eligible: eligible.length,
      inFilters: request.filterCorpus(corpus).length,
    ),
    explanations: {
      for (final photo in response.photos)
        photo.id: {
          ...?response.explanations[photo.id],
          'people': [
            for (final entry
                in (index.assignments[photo.id] ?? const {}).entries)
              if (shown.contains(entry.key))
                {
                  'person_id': entry.key,
                  'name': index.labels[entry.key],
                  'assignment': entry.value,
                },
          ],
        },
    },
  );
});

final searchResultsProvider = FutureProvider.autoDispose<List<Photo>>(
  (ref) async => (await ref.watch(searchResponseProvider.future)).photos,
);
