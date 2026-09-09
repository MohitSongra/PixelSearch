import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_logger.dart';
import '../core/ai_contract.dart';
import '../data/local/app_database.dart';
import '../data/photo_repository.dart';
import '../data/user_preferences.dart';
import '../data/indexing_preferences_repository.dart';
import '../data/search/brute_force_vector_index.dart';
import '../data/search/keyword_search_backend.dart';
import '../domain/search/search_backend.dart';
import '../domain/search/vector_index.dart';
import '../indexing/model/index_progress.dart';
import '../indexing/model/folder_selection.dart';
import '../models/photo.dart';
import 'index_bridge.dart';
import 'index_cancel_token.dart';
import 'semantic_wiring.dart';

/// Light/dark/system theme selection.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// "Privacy mode" master switch (mock): when on, all cloud features are off.
final privacyModeProvider = StateProvider<bool>((ref) => true);

/// The current search text.
final searchQueryProvider = StateProvider<String>((ref) => '');

final userPreferencesProvider = Provider<UserPreferences>(
  (ref) => UserPreferences(),
);

final skipOnboardingProvider = FutureProvider<bool>((ref) async {
  final preferences = ref.watch(userPreferencesProvider);
  return preferences.shouldSkipOnboarding(
    () async => kIsWeb ? 0 : ref.read(photoRepositoryProvider).photoCount(),
  );
});

/// Whether this platform can index a device gallery at all. Web has no gallery,
/// no ML Kit and no local database, so its UI hides the indexing controls.
bool get indexingSupported => !kIsWeb;

/// The photo library: everything the M5 indexer has persisted, newest first.
///
/// This is a *view* of the database — the only writer is the indexing pipeline
/// (via [IndexingController]), which calls [refresh] when a run finishes.
class PhotoLibrary extends StateNotifier<List<Photo>> {
  PhotoLibrary(this._ref) : super(const <Photo>[]) {
    refresh();
  }

  final Ref _ref;

  /// Re-reads the indexed photos from the store. Never throws: on web (and in
  /// unit tests) there is no database, and an unreadable store should leave the
  /// UI empty rather than take the app down.
  Future<void> refresh() async {
    if (!indexingSupported) return;
    try {
      final photos = await _ref.read(photoRepositoryProvider).loadPhotos();
      final preferences = _ref.read(userPreferencesProvider);
      await preferences.load();
      if (mounted) {
        state = photos.map(preferences.applyLabelCorrection).toList();
      }
    } catch (_) {
      // No store on this platform / not opened yet → stay empty.
    }
  }
}

final photoLibraryProvider = StateNotifierProvider<PhotoLibrary, List<Photo>>(
  (ref) => PhotoLibrary(ref),
);

// --- M5: indexing on the UI path ------------------------------------------
// The pipeline itself is untouched; what follows only *drives* it: start, stream
// progress, cancel, and refresh the library + similarity index when it's done.

/// What the indexing UI renders: the latest [IndexProgress] from the run, plus
/// whether a run is in flight and the outcome message of the last one.
@immutable
class IndexingUiState {
  const IndexingUiState({
    this.progress = IndexProgress.idle,
    this.running = false,
    this.message,
  });

  final IndexProgress progress;
  final bool running;

  /// Human-readable result of the last finished run (null while never run).
  final String? message;

  IndexingUiState copyWith({
    IndexProgress? progress,
    bool? running,
    String? message,
  }) => IndexingUiState(
    progress: progress ?? this.progress,
    running: running ?? this.running,
    message: message ?? this.message,
  );
}

/// Drives one indexing run at a time and republishes its results.
///
/// The heavy lifting stays in `IndexingService`; this only owns UI concerns —
/// single-flight, progress relay, cancellation, and the two refreshes that make
/// a completed run visible: the photo library (grid) and the warm vector index
/// (semantic search).
class IndexingController extends StateNotifier<IndexingUiState> {
  IndexingController(this._ref) : super(const IndexingUiState());

  final Ref _ref;
  IndexCancelToken? _token;

  /// Runs a full incremental pass: new and changed photos are indexed, deleted
  /// ones are dropped. Safe to call repeatedly — a second call while a run is in
  /// flight is ignored.
  Future<void> start({required FolderSelection selection}) async {
    if (state.running) return;
    final token = _token = IndexCancelToken();
    state = const IndexingUiState(
      running: true,
      progress: IndexProgress(phase: IndexPhase.scanning),
    );
    try {
      final result = await runDeviceIndexing(
        db: _ref.read(appDatabaseProvider),
        cancel: token,
        selection: selection,
        onProgress: (p) {
          if (mounted) state = state.copyWith(progress: p);
        },
      );
      if (!mounted) return;
      state = IndexingUiState(
        running: false,
        progress: result.progress ?? state.progress,
        message: _describe(result),
      );
    } catch (e) {
      if (!mounted) return;
      state = IndexingUiState(
        running: false,
        progress: const IndexProgress(phase: IndexPhase.error),
        message: 'Indexing failed: $e',
      );
    } finally {
      _token = null;
      // Whatever the outcome, committed batches are already durable — surface
      // them. Cancelled and failed runs still persisted their finished batches.
      // Skipped when disposed: the container is gone and `_ref` would throw
      // (this runs unawaited from onboarding, so it must not leak an error).
      if (mounted) {
        await _ref.read(photoLibraryProvider.notifier).refresh();
        _ref.invalidate(indexWarmupProvider);
        _logLibrarySummary();
      }
    }
  }

  /// Requests cancellation. The current batch still commits, so no work is lost.
  void cancel() => _token?.cancel();

  /// What actually landed in SQLite, read back after the refresh. Counted from
  /// the store rather than from the run, so it reports persisted state — the
  /// only thing that survives a crash or a cancel.
  void _logLibrarySummary() {
    final photos = _ref.read(photoLibraryProvider);
    final labelled = photos.where((p) => p.labels.isNotEmpty).length;
    final thumbed = photos.where((p) => p.thumbPath != null).length;
    final located = photos.where((p) => p.hasLocation).length;
    const AiLog('Indexing').info(
      'store now holds ${photos.length} photos: $labelled with ML Kit labels, '
      '$thumbed with thumbnails, $located with GPS',
    );
  }

  String _describe(IndexRunResult result) {
    switch (result.status) {
      case IndexRunStatus.noFoldersSelected:
        return 'No folders selected.';
      case IndexRunStatus.unsupported:
        return 'Indexing needs a device gallery — not available on web.';
      case IndexRunStatus.permissionDenied:
        return 'Photo access denied. Grant "Allow all photos" to index them.';
      case IndexRunStatus.modelMissing:
        return 'The CLIP image model is not installed yet '
            '(expected at ${result.message}).';
      case IndexRunStatus.modelUnusable:
        return 'The CLIP image model is installed but could not be loaded — '
            '${result.message}';
      case IndexRunStatus.finished:
        final p = result.progress!;
        final via = result.modelUsed == null ? '' : ' via ${result.modelUsed}';
        switch (p.phase) {
          case IndexPhase.done:
            final failed = p.failed > 0 ? ' · ${p.failed} skipped' : '';
            return p.total == 0
                ? 'Already up to date.'
                : 'Indexed ${p.completed} photos$failed$via.';
          case IndexPhase.cancelled:
            return 'Cancelled after ${p.completed} of ${p.total} photos.';
          default:
            return 'Indexing stopped unexpectedly after ${p.completed} photos.';
        }
    }
  }
}

final indexingControllerProvider =
    StateNotifierProvider<IndexingController, IndexingUiState>(
      (ref) => IndexingController(ref),
    );

final indexingPreferencesProvider = Provider<IndexingPreferencesRepository>(
  (ref) => IndexingPreferencesRepository(ref.watch(appDatabaseProvider)),
);

final indexFoldersProvider = FutureProvider.autoDispose<FolderCatalog>(
  (ref) => loadIndexFolders(),
);

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
/// [IndexingController] invalidates this after a run so newly-indexed photos
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
/// over the fp16 text encoder provisioned at `<support>/models/…`, assembled
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
final searchResultsProvider = FutureProvider.autoDispose<List<Photo>>((
  ref,
) async {
  final corpus = ref.watch(photoLibraryProvider);
  final backend = await ref.watch(searchBackendProvider.future);
  final query = await ref.watch(debouncedQueryProvider.future);
  return backend.search(query, corpus);
});

// --- M2: local persistence (native-only) -----------------------------------
// These are lazy: nothing reads them on web, so the web build stays green.

/// The on-device drift database (opened lazily, closed on dispose).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repository over the database — the read side of the M5 indexer and M6 search.
final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(ref.watch(appDatabaseProvider)),
);
