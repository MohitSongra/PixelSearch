import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ai_contract.dart';
import '../data/device_gallery.dart';
import '../data/local/app_database.dart';
import '../data/photo_repository.dart';
import '../data/sample_data.dart';
import '../data/search/brute_force_vector_index.dart';
import '../data/search/keyword_search_backend.dart';
import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';
import '../models/photo.dart';
import 'semantic_wiring.dart';

/// Light/dark/system theme selection.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// "Privacy mode" master switch (mock): when on, all cloud features are off.
final privacyModeProvider = StateProvider<bool>((ref) => true);

/// The current search text.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Whether device photos have been loaded (for UI state).
final deviceLoadedProvider = StateProvider<bool>((ref) => false);

/// The photo library = bundled samples, optionally merged with device photos.
class PhotoLibrary extends StateNotifier<List<Photo>> {
  PhotoLibrary(this.ref) : super(samplePhotos);

  final Ref ref;
  bool _loadingDevice = false;

  bool get deviceSupported => DeviceGallery.isSupported;

  /// Loads real device photos (mobile only) and merges them in, newest first.
  /// Returns the number of device photos added.
  Future<int> loadDevicePhotos() async {
    if (_loadingDevice) return 0;
    _loadingDevice = true;
    try {
      final device = await DeviceGallery.load(limit: 80);
      if (device.isNotEmpty) {
        final merged = [...device, ...samplePhotos]
          ..sort((a, b) => b.date.compareTo(a.date));
        state = merged;
        ref.read(deviceLoadedProvider.notifier).state = true;
      }
      return device.length;
    } finally {
      _loadingDevice = false;
    }
  }
}

final photoLibraryProvider =
    StateNotifierProvider<PhotoLibrary, List<Photo>>((ref) => PhotoLibrary(ref));

// --- M6: semantic search wiring ------------------------------------------
// The pieces below assemble the real search path behind the same
// `SearchBackend` seam (ADR-009). On web (no ONNX/DB) everything short-circuits
// to the lexical backend; on device the semantic backend degrades to lexical if
// the model isn't provisioned yet — so search always works. Native runtime
// (real model file + populated DB) is exercised on-device; the logic is proven
// in-sandbox by unit + real-ORT integration tests.

/// The shared similarity index (kept alive for the session; ANN-swappable —
/// ADR-009). Populated from the DB by [indexWarmupProvider].
final vectorIndexProvider = Provider<VectorIndex>(
  (ref) => BruteForceVectorIndex(dim: AiContract.embeddingDim),
);

/// Loads current-version image embeddings from the store into the index. Runs
/// once; when it completes, [searchBackendProvider] rebuilds so results refresh
/// against the populated index. Native-only (no DB on web). Returns the count.
final indexWarmupProvider = FutureProvider<int>((ref) async {
  final index = ref.watch(vectorIndexProvider);
  final repo = ref.watch(photoRepositoryProvider);
  final embeddings = await repo.loadEmbeddings();
  index.clear();
  embeddings.forEach(index.upsert);
  return index.length;
});

/// The active search strategy. Web → lexical (no ONNX). Native → semantic (CLIP)
/// over the fp16 text encoder provisioned at `<support>/models/…`, assembled
/// behind a conditional-import boundary ([buildSemanticBackend]) so this
/// web-reachable file never imports the AI stack. Falls back to lexical when the
/// backend can't be built. See ADR-014.
final searchBackendProvider = FutureProvider<SearchBackend>((ref) async {
  final index = ref.watch(vectorIndexProvider);
  if (!kIsWeb) {
    ref.watch(indexWarmupProvider); // trigger DB→index population (non-blocking)
  }
  final semantic = await buildSemanticBackend(index); // null on web / not ready
  return semantic ?? const KeywordSearchBackend();
});

/// Debounced mirror of [searchQueryProvider]: a non-empty query is delayed
/// ~300 ms so we embed once the user pauses, not on every keystroke. Because
/// this is autoDispose, a superseding keystroke cancels the pending delay.
final debouncedQueryProvider = FutureProvider.autoDispose<String>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return '';
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return q;
});

/// Ranked results for the current (debounced) query over the library. Async
/// because semantic ranking runs the text encoder; the UI renders its
/// [AsyncValue] (spinner while embedding, previous results kept).
final searchResultsProvider =
    FutureProvider.autoDispose<List<Photo>>((ref) async {
  final corpus = ref.watch(photoLibraryProvider);
  final backend = await ref.watch(searchBackendProvider.future);
  final query = await ref.watch(debouncedQueryProvider.future);
  return backend.search(query, corpus);
});

// --- M2: local persistence (native-only). Additive — not yet on the UI path.
// These are lazy: nothing reads them on web, so the web build stays green.

/// The on-device drift database (opened lazily, closed on dispose).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repository over the database — used by the M5 indexer and M6 search.
final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(ref.watch(appDatabaseProvider)),
);
