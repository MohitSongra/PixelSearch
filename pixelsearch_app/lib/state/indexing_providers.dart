import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_logger.dart';
import '../data/indexing_preferences_repository.dart';
import '../data/local/processing_lease.dart';
import '../indexing/model/index_progress.dart';
import '../indexing/model/folder_selection.dart';
import 'index_bridge.dart';
import 'index_cancel_token.dart';
import 'library_providers.dart';
import 'people_providers.dart';
import 'search_providers.dart';
import 'storage_providers.dart';

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
    ProcessingLease? lease;
    try {
      await _ref.read(peopleControllerProvider).suspend();
      lease = await ProcessingLease.acquire(
        _ref.read(appDatabaseProvider),
        'foreground-index',
        onLost: token.cancel,
      );
      if (lease == null) {
        throw StateError(
          'Background indexing is already running. Try again after it finishes.',
        );
      }
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
      await lease?.release();
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
